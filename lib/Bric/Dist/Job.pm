package Bric::Dist::Job;

=head1 NAME

Bric::Dist::Job - Manages Bricolage distribution jobs.

=head1 VERSION

$Revision: 1.13 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.13 $ )[-1];

=head1 DATE

$Date: 2003-01-22 05:36:04 $

=head1 SYNOPSIS

  use Bric::Dist::Job;

  my $id = 1;
  my $format = "%D %T";

  # Constructors.
  my $job = Bric::Dist::Job->new($init);
  $job = Bric::Dist::Job->lookup({ id => $id });
  my @jobs = Bric::Dist::Job->list($params);

  # Class Methods.
  my @job_ids = Bric::Dist::Job->list_ids($params);

  # Instance Methods
  my $id = $job->get_id;

  my $type = $job->get_type;
  $job = $job->set_type($type);

  my $sched_time = $job->get_sched_time($format);
  $job = $job->set_sched_time($sched_time);
  my $comp_time = $job->get_comp_timeget_comp_time($format);

  my @resources = $job->get_resources;
  my @resource_ids = $job->get_resource_ids;
  $job = $job->set_resource_ids(@resource_ids);

  my @server_types = $job->get_server_types;
  my @server_type_ids = $job->get_server_type_ids;
  $job = $job->set_server_type_ids(@server_type_ids);

  # Save the job.
  $job = $job->save;

  # Cancel the job.
  $job = $job->cancel;

  # Execute the job.
  $job = $job->execute_me;

=head1 DESCRIPTION

This class manages distribution jobs. A job is a list of things to be
transformed by actions and moved out, all at a scheduled time. The idea is that
Bricolage will schedule a job and then it will be executed at its scheduled
times. There are two types of jobs, "Deliver" and "Expire".

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Config qw(:dist :temp);
use Bric::Util::DBI qw(:all);
use Bric::Util::Time qw(:all);
use Bric::Util::Trans::FS;
use Bric::Util::Coll::Resource;
use Bric::Util::Coll::ServerType;
use Bric::Util::Fault::Exception::DP;
use Bric::Util::Fault::Exception::GEN;
use Bric::Util::Grp::Job;
use Bric::App::Event qw(log_event);
use File::Spec::Functions qw(catdir);

################################################################################
# Inheritance
################################################################################
use base qw(Bric);

################################################################################
# Function and Closure Prototypes
################################################################################
my ($get_em, $get_coll, $set_pend);

################################################################################
# Constants
################################################################################
use constant DEBUG => 0;
use constant GROUP_PACKAGE => 'Bric::Util::Grp::Job';
use constant INSTANCE_GROUP_ID => 30;

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields
my @cols = qw(id name expire usr__id sched_time comp_time tries pending);
my @props = qw(id name type user_id sched_time comp_time tries _pending);
my @ord = @props[1..$#props - 1];

my @scol_args = ('Bric::Util::Coll::ServerType', '_server_types');
my @rcol_args = ('Bric::Util::Coll::Resource', '_resources');
my $dp = 'Bric::Util::Fault::Exception::DP';
my $gen = 'Bric::Util::Fault::Exception::GEN';
my $meths;

my %num_map = ( id => 'id = ?',
		user_id => 'user__id = ?',
		server_type_id => "id IN (SELECT job__id from job__server_type"
		                  . " WHERE job__id = ?)",
		resource_id => "id IN (SELECT job__id from job__resource"
                               . " WHERE job__id = ?)"
);

################################################################################

################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({
			 # Public Fields
			 id => Bric::FIELD_READ,
			 name => Bric::FIELD_RDWR,
			 user_id => Bric::FIELD_RDWR,
			 sched_time => Bric::FIELD_NONE,
			 comp_time => Bric::FIELD_NONE,
			 type => Bric::FIELD_RDWR,
			 tries => Bric::FIELD_READ,

			 # Private Fields
			 _resources => Bric::FIELD_NONE,
			 _resource_ids => Bric::FIELD_NONE,
			 _server_types => Bric::FIELD_NONE,
			 _server_type_ids => Bric::FIELD_NONE,
			 _cancel => Bric::FIELD_NONE,
			 _pending => Bric::FIELD_NONE
			});
}

################################################################################
# Class Methods
################################################################################

=head1 INTERFACE

=head2 Constructors

=over 4

=item my $job = Bric::Dist::Job->new($init)

Instantiates a Bric::Dist::Job object. An anonymous hash of initial values may be
passed. The supported initial value keys are:

=over 4

=item *

name - A name for the job. Required.

=item *

user_id - The ID of the user scheduling the job.

=item *

sched_time - The time at which to execute the job. If undef, the job will
be executed immediately.

=item *

resources - An anonymous array of Bric::Dist::Resource objects representing the
files and/or directories on which the job's actions will be executed.

=item *

server_types - An anonymous array of Bric::Dist::ServerTypeBric::Dist::ServerType
objects representing the types of servers for which the job must be executed.
See Bric::Dist::ServerType for an interface for creating server types.

=back

Either the resources, resource_names, or resource_ids anonymous array is must be
passed in, as must either sever_types, server_type_names, or server_type_ids.

B<Throws:>

=over 4

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=item *

Bric::_get() - Problems retrieving fields.

=item *

Cannot add resources to a completed job.

=item *

Cannot add resources to a pending job.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub new {
    my ($pkg, $init) = @_;
    my $self = bless {}, ref $pkg || $pkg;
    # Add server types and resources.
    $self->add_server_types(@{ delete $init->{server_types} })
      if $init->{server_types};
    $self->add_resources(@{ delete $init->{resources} }) if $init->{resources};

    # Set the type, schedule time, and the _pending and tries defaults.
    $init->{type} = $init->{type} ? 1 : 0;
    $init->{sched_time} = db_date($init->{sched_time}) if $init->{sched_time};
    @{$init}{qw(_pending tries)} = (0, 0);
    $self->SUPER::new($init);
}

################################################################################

=item my $job = Bric::Dist::Job->lookup({ id => $id })

Looks up and instantiates a new Bric::Dist::Job object based on the Bric::Dist::Job
object ID passed. If $id is not found in the database, lookup() returns undef.

B<Throws:>

=over

=item *

Too many Bric::Dist::Job objects found.

=item *

Unable to prepare SQL statement.

=item *

Unable to connect to database.

=item *

Unable to select column into arrayref.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> If $id is found, populates the new Bric::Dist::Job object with
data from the database before returning it.

B<Notes:> NONE.

=cut

sub lookup {
    my $job = &$get_em(@_);
    # We want @$job to have only one value.
    die $dp->new({ msg => 'Too many Bric::Dist::Job objects found.' })
      if @$job > 1;
    return @$job ? $job->[0] : undef;
}

################################################################################

=item my (@jobs || $jobs_aref) = Bric::Dist::Job->list($params)

Returns a list or anonymous array of Bric::Dist::Job objects based on the search
parameters passed via an anonymous hash. The supported lookup keys are:

=over 4

=item *

name - The name of the jobs. May use typical SQL wildcard '%'. Note that the
query is case-insensitve.

=item *

user_id - The ID of the user who scheduled the jobs.

=item *

sched_time - May pass in as an anonymous array of two values, the first the
minimum scheduled time, the second the maximum scheduled time. If the first
array item is undefined, then the second will be considered the date that
sched_time must be less than. If the second array item is undefined, then the
first will be considered the date that sched_time must be greater than. If the
value passed in is undefined, then the query will specify 'IS NULL'.

=item *

comp_time - May pass in as an anonymous array of two values, the first the
minimum completion time, the second the maximum completion time. If the first
array item is undefined, then the second will be considered the date that
sched_time must be less than. If the second array item is undefined, then the
first will be considered the date that sched_time must be greater than. If the
value passed in is undefined, then the query will specify 'IS NULL'.

=item *

resource_id - A Bric::Dist::Resource object ID.

=item *

server_type_id - A Bric::Dist::ServerType object ID.

=back

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select column into arrayref.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> Populates each Bric::Dist::Job object with data from the database
before returning them all.

B<Notes:> NONE.

=cut

sub list { wantarray ? @{ &$get_em(@_) } : &$get_em(@_) }

################################################################################

=back

=head2 Destructors

=over 4

=item $job->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=back

=cut

sub DESTROY {}

################################################################################

=head2 Public Class Methods

=over

=item my (@job_ids || $job_ids_aref) = Bric::Dist::Job->list_ids($params)

Returns a list or anonymous array of Bric::Dist::Job object IDs based on the
search criteria passed via an anonymous hash. The supported lookup keys are the
same as those for list().

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select column into arrayref.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub list_ids { wantarray ? @{ &$get_em(@_, 1) } : &$get_em(@_, 1) }

################################################################################

=item $meths = Bric::Dist::Job >my_meths

=item (@meths || $meths_aref) = Bric::Dist::Job->my_meths(TRUE)

Returns an anonymous hash of instrospection data for this object. If called
with a true argument, it will return an ordered list or anonymous array of
intrspection data. The format for each introspection item introspection is as
follows:

Each hash key is the name of a property or attribute of the object. The value
for a hash key is another anonymous hash containing the following keys:

=over 4

=item name

The name of the property or attribute. Is the same as the hash key when an
anonymous hash is returned.

=item disp

The display name of the property or attribute.

=item get_meth

A reference to the method that will retrieve the value of the property or
attribute.

=item get_args

An anonymous array of arguments to pass to a call to get_meth in order to
retrieve the value of the property or attribute.

=item set_meth

A reference to the method that will set the value of the property or
attribute.

=item set_args

An anonymous array of arguments to pass to a call to set_meth in order to set
the value of the property or attribute.

=item type

The type of value the property or attribute contains. There are only three
types:

=over 4

=item short

=item date

=item blob

=back

=item len

If the value is a 'short' value, this hash key contains the length of the
field.

=item search

The property is searchable via the list() and list_ids() methods.

=item req

The property or attribute is required.

=item props

An anonymous hash of properties used to display the property or
attribute. Possible keys include:

=over 4

=item type

The display field type. Possible values are

=over 4

=item text

=item textarea

=item password

=item hidden

=item radio

=item checkbox

=item select

=back

=item length

The Length, in letters, to display a text or password field.

=item maxlength

The maximum length of the property or value - usually defined by the SQL DDL.

=back

=item rows

The number of rows to format in a textarea field.

=item cols

The number of columns to format in a textarea field.

=item vals

An anonymous hash of key/value pairs reprsenting the values and display names
to use in a select list.

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub my_meths {
    my ($pkg, $ord) = @_;

    # Return 'em if we got em.
    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}]
      if $meths;

    # We don't got 'em. So get 'em!
    $meths = {
	      name        => {
			      name     => 'name',
			      get_meth => sub { shift->get_name(@_) },
			      get_args => [],
			      set_meth => sub { shift->set_name(@_) },
			      set_args => [],
			      disp     => 'Name',
			      search   => 1,
			      len      => 64,
			      req      => 1,
			      type     => 'short',
			      props    => { type      => 'text',
					    length    => 32,
					    maxlength => 64
					  }
			     },
	      type       => {
			      name     => 'type',
			      get_meth => sub { shift->get_type(@_) },
			      get_args => [],
			      set_meth => sub { shift->set_type(@_) },
			      set_args => [],
			      disp     => 'Type',
			      len      => 1,
			      req      => 1,
			      type     => 'short',
			      props    => { type => 'radio',
					    vals => [ [0, 'Deliver'],
						      [1, 'Expire'] ]
					  }
			     },
	      user_id     => {
			      name     => 'user_id',
			      get_meth => sub { shift->get_user_id(@_) },
			      get_args => [],
			      disp     => 'Scheduler',
			      len      => 1,
			      type     => 'short',
			     },
	      sched_time => {
			      name     => 'sched_time',
			      get_meth => sub { shift->get_sched_time(@_) },
			      get_args => [],
			      set_meth => sub { shift->set_sched_time(@_) },
			      set_args => [],
			      disp     => 'Scheduled Time',
			      len      => 64,
			      req      => 0,
			      type     => 'short',
			      props    => { type      => 'date' }
			     },
	      comp_time   => {
			      name     => 'comp_time',
			      get_meth => sub { shift->get_comp_time(@_) },
			      get_args => [],
			      set_meth => sub { shift->set_comp_time(@_) },
			      set_args => [],
			      disp     => 'Completion Time',
			      len      => 64,
			      req      => 0,
			      type     => 'short',
			      props    => { type      => 'date' }
			     },
	      tries      => {
			      name     => 'tries',
			      get_meth => sub { shift->get_tries(@_) },
			      get_args => [],
			      disp     => 'Attempts',
			      len      => 1,
			      type     => 'short',
			     },
	     };
    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}];
}

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item my $id = $job->get_id

Returns the ID of the Bric::Dist::Job object.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'id' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> If the Bric::Dist::Job object has been instantiated via the new()
constructor and has not yet been C<save>d, the object will not yet have an ID,
so this method call will return undef.

=item my $name = $job->get_name

Returns the name of the Bric::Dist::Job object.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'name' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $st->set_name($name)

Sets the server type name.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_name { $_[0]->_set( ['name'] => [substr $_[1], 0, 256] ) }

=item my $user_id = $job->get_user_id

Returns the user_id of the Bric::Dist::Job object.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'user_id' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $st->set_user_id($user_id)

Sets the server type user_id.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'user_id' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $sched_time = $job->get_sched_time($format)

Returns the time at which the job is scheduled to execute. Pass in a strftime
format string to get the time back in that format.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to unpack date.

=item *

Unable to format date.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_sched_time { local_date($_[0]->_get('sched_time'), $_[1]) }

################################################################################

=item $self = $job->set_sched_time($sched_time)

Sets the time at which the job is to be executed. This method will not set the
scheduled time and will return undef if the job has already been completed.

B<Throws:>

=over 4

=item *

Cannot change scheduled time on completed job.

=item *

Cannot change scheduled time on pending job.

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to unpack date.

=item *

Unable to format date.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_sched_time {
    my ($self, $time) = @_;
    die $gen->new({ msg => "Cannot change scheduled time on completed job." })
      if $self->_get('comp_time');
    die $gen->new({ msg => "Cannot change scheduled time on pending job." })
      if $self->_get('_pending');
    $self->_set( ['sched_time'], [db_date($time)] );
}

################################################################################

=item my $comp_time = $job->get_comp_time($format)

Returns the time at which the job was completed. Returns undef if the job has
not yet been completed. Pass in a strftime format string to get the time back in
that format.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to unpack date.

=item *

Unable to format date.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_comp_time { local_date($_[0]->_get('comp_time'), $_[1]) }

################################################################################

=item my $tries = $foo->get_tries

Returns the number of times the job attempted to be executed.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'tries' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my (@resources || $resources_aref) = $job->get_resources

=item my (@resources || $resources_aref) = $job->get_resources(@resource_ids)

Returns a list or anonymous array of the Bric::Dist::Resource objects that
represent the directories and/or files on which this job acts.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select column into arrayref.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_resources {
    my $col = &$get_coll(shift, @rcol_args);
    $col->get_objs(@_);
}

################################################################################

=item $job = $job->add_resources(@resources)

Adds resources to this job. Call save() to save the relationship. Resources
cannot be added to a job after the job has executed. Trying to add resources
after a job has completed will throw an exception.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Cannot add resources to a completed job.

=item *

Cannot add resources to a pending job.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::Coll::Server internally.

=cut

sub add_resources {
    my $self = shift;
    die $gen->new({ msg => "Cannot add resources to a completed job." })
      if $self->_get('comp_time');
    die $gen->new({ msg => "Cannot add resources to a pending job." })
      if $self->_get('_pending');
    my $col = &$get_coll($self, @rcol_args);
    $col->add_new_objs(@_);
    $self->_set__dirty(1);
}

################################################################################

=item $self = $job->del_resources(@resources)

Dissociates resources, represented as Bric::Dist::Resource objects, from the job.
call save() to save the dissociations to the database.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Cannot delete resources from a completed job.

=item *

Cannot delete resources from a pending job.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select column into arrayref.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub del_resources {
    my $self = shift;
    die $gen->new({ msg => "Cannot delete resources from a completed job." })
      if $self->_get('comp_time');
    die $gen->new({ msg => "Cannot delete resources from a pending job." })
      if $self->_get('_pending');
    my $col = &$get_coll($self, @rcol_args);
    $col->del_objs(@_);
    $self->_set__dirty(1);
}

################################################################################

=item my (@server_types || $server_types_aref) = $job->get_server_types

=item my (@server_types || $server_types_aref) =
$job->get_server_types(@server_type_ids)

Returns a list or anonymous array of the Bric::Dist::ServerType objects that
represent the directories and/or files on which this job acts.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select column into arrayref.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_server_types {
    my $col = &$get_coll(shift, @scol_args);
    $col->get_objs(@_);
}

################################################################################

=item $job = $job->add_server_types(@server_types)

Adds server types to this job. Call save() to save the relationship. Server
types cannot be added to a job after the job has executed. Trying to add
server types after a job has completed will throw an exception.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Cannot add server types to a completed job.

=item *

Cannot add server types to a pending job.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::Coll::Server internally.

=cut

sub add_server_types {
    my $self = shift;
    die $gen->new({ msg => "Cannot add server types to a completed job." })
      if $self->_get('comp_time');
    die $gen->new({ msg => "Cannot add server types to a pending job." })
      if $self->_get('_pending');
    my $col = &$get_coll($self, @scol_args);
    $col->add_new_objs(@_);
    $self->_set__dirty(1);
}

################################################################################

=item $self = $job->del_server_types(@server_types)

Dissociates server types, represented as Bric::Dist::ServerType objects, from the
job. call save() to save the dissociations to the database.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Cannot delete server types from a completed job.

=item *

Cannot delete server types from a pending job.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select column into arrayref.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub del_server_types {
    my $self = shift;
    die $gen->new({ msg => "Cannot delete server types from a completed job." })
      if $self->_get('comp_time');
    die $gen->new({ msg => "Cannot delete server types from a pending job." })
      if $self->_get('_pending');
    my $col = &$get_coll($self, @scol_args);
    $col->del_objs(@_);
    $self->_set__dirty(1);
}

################################################################################

=item $self = $job->is_pending

Returns true ($self) if the job is pending (that is, in the process of being
executed), and undef it is not.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub is_pending { $_[0]->_get('_pending') ? $_[0] : undef }

################################################################################

=item $self = $job->cancel

Markes this job for cancellation. Call save() to delete it from the database.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Cannot cancel completed job.

=item *

Cannot cancel pending job.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub cancel {
    my $self = shift;
    die $gen->({ msg => "Cannot cancel completed job." })
      if $self->_get('_comp_time');
    die $gen->new({ msg => "Cannot cancel pending job." })
      if $self->_get('_pending');
    $self->_set({_cancel => 1 });
}

################################################################################

=item $self = $job->save

Saves any changes to the Bric::Dist::Job object. Returns $self on success and
undef on failure.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=item *

Unable to select row.

=item *

Incorrect number of args to _set.

=item *

Bric::_set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub save {
    my $self = shift;
    return unless $self->_get__dirty;
    my ($id, $cancel, $res, $sts) =
      $self->_get(qw(id _cancel _resources _server_types));

    if (defined $id && $cancel) {
	# It has been marked for deletion. So do it!
	my $del = prepare_c(qq{
            DELETE FROM job
            WHERE  id = ?
        });
	execute($del, $id);
    } elsif (defined $id) {
	# Existing record. Update it.
	local $" = ' = ?, '; # Simple way to create placeholders with an array.
	my $upd = prepare_c(qq{
            UPDATE job
            SET    @cols = ?
            WHERE  id = ?
        });
	execute($upd, $self->_get(@props), $id);
    } else {
	# It's a new job. Insert it.
	# Default schedule time to now.
	$self->_set(['sched_time'], [db_date(0, 1)])
	  unless $self->_get('sched_time');

	local $" = ', ';
	my $fields = join ', ', next_key('job'), ('?') x $#cols;
	my $ins = prepare_c(qq{
            INSERT INTO job (@cols)
            VALUES ($fields)
        }, undef, DEBUG);

	# Don't try to set ID - it will fail!
	my @ps = $self->_get(@props[1..$#props]);
	execute($ins, $self->_get(@props[1..$#props]));

	# Now grab the ID.
	$id = last_key('job');
	$self->_set(['id'], [$id]);

	# Now execute the job if distribution is enabled.
	$self->execute_me if ENABLE_DIST && $self->get_sched_time('epoch') <= time;

	# And finally, register this person in the "All Jobs" group.
	$self->register_instance(INSTANCE_GROUP_ID, GROUP_PACKAGE);
    }
    $res->save($id) if $res;
    $sts->save($id) if $sts;
    $self->SUPER::save;
    return $self;
}

################################################################################

=item $self = $job->execute_me

Executes the job. This means the for each of the server types associated with
this job, the list of actions will be performed on each file, hopefully
culminating in the distribution of the resources to the servers associated with
the server type. At the end of the process, a completion time will be saved
to the database. Attempting to execute a job before its scheduled time will
throw an exception.

B<Throws:> Quite a few exceptions can be thrown here. Check the do_it() methods
on all Bric::Dist::Action subclasses, as well as the put_res() methods of the
mover classes (e.g., Bric::Util::Trans::FS). Here are the exceptions thrown from
withing this method itself.

=over 4

=item *

Cannot execute job before its scheduled time.

=item *

Cannot execute job that has already been executed.

=item *

Can't get a lock on job.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub execute_me {
    my $self = shift;
    # Check to make sure we can actually do this.
    die $gen->new({ msg => "Cannot execute job before its scheduled time."})
      if $self->get_sched_time('epoch') > time;
    die $gen->new({msg => "Cannot execute job that has already been executed."})
      if $self->get_comp_time;

    # Mark this job pending.
    &$set_pend($self, 1) || die
      $dp->new({msg => "Can't get a lock on job No. " . $self->get_id . '.' });

    eval {
	# Grab all of the resources.
	my $resources = $self->get_resources;
	# Figure out what we're doing here.
	if ($self->get_type) {
	    # This is an expiration job.
	    foreach my $st ($self->get_server_types) {
		# Go through the actions in reverse order.
		foreach my $a (reverse $st->get_actions) {
		    # Undo the action.
		    my $ret = $a->undo_it($resources, $st);
		    if ($ret) {
			my $type = $a->get_type;
			next if $type eq 'Move';
		    grep { log_event('resource_undo_action', $_,
				     { Action => $type } ) } @$resources;
		    }
		}
	    }
	} else {
	    # A Delivery job. Go through the server types one at a time.
	    foreach my $st ($self->get_server_types) {
		if ($st->can_copy) {
		    # The resources should be copied to a temporary directory.
		    my $fs = Bric::Util::Trans::FS->new;
		    foreach my $res (@$resources) {
			# Create the temporary resource path.
			my $path = $res->get_path;
			my $tmp_path = catdir TEMP_DIR, $path;
			# Copy the resources to the tmp location.
			$fs->copy($path, $tmp_path);
			# Add the temporary path to the resource.
			$res->set_tmp_path($tmp_path);
		    }
		}
		# Okay, we know where the resources are on disk. Let's
		# perform each of the actions in turn.
		foreach my $a ($st->get_actions) {
		    # Execute the action.
		    $a->do_it($resources, $st);
		    # Grab the action type and log the action for each resource.
		    my $type = $a->get_type;
		    next if $type eq 'Move';
		    grep { log_event('resource_action', $_,
				     { Action => $type } ) } @$resources;
		}
	    }
	}
    };

    if (my $err = $@) {
	# Hmmm...something went wrong.
	if ($self->_get('tries') >= DIST_ATTEMPTS) {
	    # We've met or exceeded the maximum number of attempts. Mark the job
	    # completed and then log an event.
	    $self->_set([qw(comp_time _pending)], [db_date(0, 1), 0]);
	} else {
	    # We're gonna try again. Unlock the job.
	    $self->_set([qw(_pending)], [0]);
	}
	# Save our changes and proceed with the die.
	$self->save;
	die $err;
    }
    # Mark it complete, unlock it, and we're done!
    $self->_set([qw(comp_time _pending)], [db_date(0, 1), 0]);
    $self->save;
}

################################################################################

=back

=head1 PRIVATE

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

=over 4

=item my $_aref = &$get_em( $pkg, $params )

=item my $_ids_aref = &$get_em( $pkg, $params, 1 )

Function used by lookup() and list() to return a list of Bric::Dist::Job objects
or, if called with an optional third argument, returns a listof Bric::Dist::Job
object IDs (used by list_ids()).

B<Throws:>

=over 4

=item *

Unable to prepare SQL statement.

=item *

Unable to connect to database.

=item *

Unable to select column into arrayref.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$get_em = sub {
    my ($pkg, $params, $ids, $href) = @_;
    my (@wheres, @params);
    while (my ($k, $v) = each %$params) {
	if ($k eq 'name') {
	    push @wheres, "LOWER($k) LIKE ?";
	    push @params, lc $v;
	} elsif ($num_map{$k}) {
	    push @wheres, $num_map{$k};
	    push @params, $v;
	} else {
	    # It's a date column.
	    if (ref $v) {
		# It's an arrayref of dates.
		if (!defined $v->[0]) {
		    # It's less than.
		    push @wheres, "$k < ?";
		    push @params, db_date($v->[1]);
		} elsif (!defined $v->[1]) {
		    # It's greater than.
		    push @wheres, "$k > ?";
		    push @params, db_date($v->[0]);
		} else {
		    # It's between two sizes.
		    push @wheres, "$k BETWEEN ? AND ?";
		    push @params, (db_date($v->[0]), db_date($v->[1]));
		}
	    } elsif (!defined $v) {
		# It needs to be null.
		push @wheres, "$k IS NULL";
	    } else {
		# It's a single value.
		push @wheres, "$k = ?";
		push @params, db_date($v);
	    }
	}
    }

    # Assemble the WHERE statement.
    my $where = @wheres ? "\n        WHERE " .
      join "\n               AND ", @wheres : '';

    # Assemble the query.
    local $" = ', ';
    my $qry_cols = $ids ? ['id'] : \@cols;
    my $sel = prepare_ca(qq{
        SELECT @$qry_cols
        FROM   job $where
        ORDER BY sched_time, id
    }, undef, DEBUG);

    # Just return the IDs, if they're what's wanted.
    return col_aref($sel, @params) if $ids;

    $pkg = ref $pkg || $pkg;
    execute($sel, @params);
    my (@d, @jobs);
    $pkg = ref $pkg || $pkg;
    bind_columns($sel, \@d[0..$#cols]);
    while (fetch($sel)) {
	my $self = bless {}, $pkg;
	$self->SUPER::new;
	$self->_set(\@props, \@d);
	$self->_set__dirty; # Disables dirty flag.
	push @jobs, $self;
    }
    return \@jobs;
};

=item my $coll = &$get_coll($self, $class, $key)

Returns the collection for this job. Pass in the $job object itself, the
property key for storing the collection, and the name of the collection class.
The collection is a Bric::Util::Coll object. See Bric::Util::Coll for interface
details.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to prepare SQL statement.

=item *

Unable to connect to database.

=item *

Unable to select column into arrayref.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$get_coll = sub {
    my ($self, $class, $key) = @_;
    my $dirt = $self->_get__dirty;
    my ($id, $coll) = $self->_get('id', $key);
    $self->_set__dirty($dirt); # Reset the dirty flag.
    return $coll if $coll;
    $coll = $class->new(defined $id ? { job_id => $id } : undef);
    $self->_set([$key], [$coll]);
    return $coll;
};

=item my $bool = &$set_pend($self, $value)

Sets the pending column in the database, as well as the pending property in the
job object. Used by execute().

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$set_pend = sub {
    my ($self, $value) = @_;
    my ($id, $exec) = $self->_get(qw(id tries));
    $exec++;
    my $upd = prepare_c(qq{
        UPDATE job
        SET    pending = ?,
               tries = ?
        WHERE  id = ?
               AND pending <> ?
    });
    my $ret = execute($upd, $value, $exec, $id, $value);
    return if $ret eq '0E0';
    $self->_set([qw(_pending tries)], [$value, $exec]);
    return $ret;
};

1;
__END__

=back

=head1 NOTES

NONE.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<Bric|Bric>, 
L<Bric::Dist::Resource|Bric::Dist::Resource>, 
L<Bric::Dist::ServerType|Bric::Dist::ServerType>

=cut
