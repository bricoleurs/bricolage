package Bric::Util::Job;

=head1 NAME

Bric::Util::Job - Manages Bricolage distribution jobs.

=head1 VERSION

$LastChangedRevision$

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 DATE

$Id$

=head1 SYNOPSIS

  use Bric::Util::Job;

  my $id = 1;
  my $format = "%D %T";

  # Constructors.
  my $job = Bric::Util::Job->new($init);
  $job = Bric::Util::Job->lookup({ id => $id });
  my @jobs = Bric::Util::Job->list($params);

  # Class Methods.
  my @job_ids = Bric::Util::Job->list_ids($params);

  # Instance Methods
  my $id = $job->get_id;

  my $type = $job->get_type;
  $job = $job->set_type($type);

  my $sched_time = $job->get_sched_time($format);
  $job = $job->set_sched_time($sched_time);
  my $comp_time = $job->get_comp_time($format);

  my @resources = $job->get_resources;
  my @resource_ids = $job->get_resource_ids;
  $job = $job->set_resource_ids(@resource_ids);

  my @server_types = $job->get_server_types;
  my @server_type_ids = $job->get_server_type_ids;
  $job = $job->set_server_type_ids(@server_type_ids);

  my $boolean = $job->get_failed;
  $job = $job->set_failed($boolean);

  my $err_msg = $job->get_error_message;

  my $boolean = $job->get_executing;

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
use Bric::Config qw(:dist :temp STAGE_ROOT);
use Bric::App::Event qw(:all);
use Bric::Util::DBI qw(:all);
use Bric::Util::Time qw(:all);
use Bric::Util::Fault qw(:all);
use Bric::Util::Trans::FS;
use Bric::Util::Coll::Resource;
use Bric::Util::Coll::ServerType;
use Bric::Util::Grp::Job;
use Bric::Util::Burner;
use File::Spec::Functions qw(catdir);
use Bric::App::Event qw(log_event);
use Scalar::Util qw(blessed);

################################################################################
# Inheritance
################################################################################
use base qw(Bric);

################################################################################
# Function and Closure Prototypes
################################################################################
my ($get_em, $get_coll, $set_executing, $check_priority);

################################################################################
# Constants
################################################################################
use constant DEBUG => 0;
use constant GROUP_PACKAGE => 'Bric::Util::Grp::Job';
use constant INSTANCE_GROUP_ID => 30;
use constant NAME_MAX_LENGTH => 246;

my $PKG_MAP = {
    54 => 'Bric::Util::Job',
    79 => 'Bric::Util::Job::Dist',
    80 => 'Bric::Util::Job::Pub',
};

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields
my @COLS = qw(id name expire usr__id sched_time priority comp_time tries
              error_message executing story_instance__id media_instance__id
              class__id failed);
my @PROPS = qw(id name type user_id sched_time priority comp_time tries
               error_message _executing story_instance_id media_instance_id
               _class_id _failed);
my @ORD = @PROPS[1..$#PROPS - 6];

my $SEL_COLS = 'a.id, a.name, a.expire, a.usr__id, a.sched_time, a.priority, '
  . 'a.comp_time, a.tries, a.error_message, a.executing, a.story_instance__id, '
  . 'a.media_instance__id, a.class__id, a.failed, m.grp__id';
my @SEL_PROPS = (@PROPS, 'grp_ids');

my @SCOL_ARGS = ('Bric::Util::Coll::ServerType', '_server_types');
my @RCOL_ARGS = ('Bric::Util::Coll::Resource', '_resources');
my $meths;

################################################################################

################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({
                         # Public Fields
                         id                => Bric::FIELD_READ,
                         name              => Bric::FIELD_RDWR,
                         user_id           => Bric::FIELD_RDWR,
                         sched_time        => Bric::FIELD_READ,
                         priority          => Bric::FIELD_RDWR,
                         comp_time         => Bric::FIELD_READ,
                         type              => Bric::FIELD_RDWR,
                         tries             => Bric::FIELD_READ,
                         grp_ids           => Bric::FIELD_READ,
                         story_instance_id => Bric::FIELD_RDWR,
                         media_instance_id => Bric::FIELD_RDWR,
                         error_message     => Bric::FIELD_READ,

                         # Private Fields
                         _resources        => Bric::FIELD_NONE,
                         _resource_ids     => Bric::FIELD_NONE,
                         _server_types     => Bric::FIELD_NONE,
                         _server_type_ids  => Bric::FIELD_NONE,
                         _cancel           => Bric::FIELD_NONE,
                         _executing        => Bric::FIELD_NONE,
                         _class_id         => Bric::FIELD_NONE,
                         _failed           => Bric::FIELD_NONE,
                        });
}

################################################################################
# Class Methods
################################################################################

=head1 INTERFACE

=head2 Constructors

=over 4

=item my $job = Bric::Util::Job->new($init)

Instantiates a Bric::Util::Job object. An anonymous hash of initial values may be
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

server_types - An anonymous array of Bric::Dist::ServerType
objects representing the types of servers for which the job must be executed.
See Bric::Dist::ServerType for an interface for creating server types.

=item *

type - The type of job. Pass a true value for an expire job and a false value
(or no C<type> parameter at all) for a distribution job.

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

Cannot add resources to a executing job.

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

    # Check for a legitimate Class ID, or die.
    my $class = Bric::Util::Class->lookup({ pkg_name => $pkg });
    $self->_set({ _class_id => $class->get_id });

    # Set the type and the _executing and tries defaults.
    $init->{type} = $init->{type} ? 1 : 0;
    @{$init}{qw(_executing tries _failed)} = (0, 0, 0);

    # check priority, and default to 3
    if (defined $init->{priority}) {
        &$check_priority($init->{priority});
    } else {
        $init->{priority} = 3;
    }

    # Check for the old story_id and media_id parameters.
    for my $doc_type (qw(story media)) {
        my $doc_id = delete $init->{"$doc_type\_id"} or next;
        next if $init->{"$doc_type\_instance_id"};
        # Bah, we'll have to look up the latest instance ID.
        my $pkg = 'Bric::Biz::Asset::Business::' . ucfirst $doc_type;
        my $doc = $pkg->lookup({ id => $doc_id })
            or throw_dp "No $doc_type object with the ID $doc_id";
        $init->{"$doc_type\_instance_id"} = $doc->get_version_id;
    }

    # Default schedule time to now.
    $init->{sched_time} = db_date($init->{sched_time}, 1);
    $self->SUPER::new($init);
}

################################################################################

=item my $job = Bric::Util::Job->lookup({ id => $id })

Looks up and instantiates a new Bric::Util::Job object based on the Bric::Util::Job
object ID passed. If $id is not found in the database, lookup() returns undef.

B<Throws:>

=over

=item *

Too many Bric::Util::Job objects found.

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

B<Side Effects:> If $id is found, populates the new Bric::Util::Job object with
data from the database before returning it.

B<Notes:> NONE.

=cut

sub lookup {
    my $pkg = shift;
    my $job = $pkg->cache_lookup(@_);
    return $job if $job;

    $job = $get_em->($pkg, @_);
    # We want @$job to have only one value.
    throw_dp({ error => 'Too many Bric::Util::Job objects found.' })
      if @$job > 1;
    return @$job ? $job->[0] : undef;
}

################################################################################

=item my (@jobs || $jobs_aref) = Bric::Util::Job->list($params)

Returns a list or anonymous array of Bric::Util::Job objects based on the search
parameters passed via an anonymous hash. The supported lookup keys are:

=over 4

=item id

Job ID. May use C<ANY> for a list of possible values.

=item name

The name of the jobs. May use typical SQL wildcard '%'. Note that the query is
case-insensitve. May use C<ANY> for a list of possible values.

=item user_id

The ID of the user who scheduled the jobs. May use C<ANY> for a list of
possible values.

=item sched_time

May pass in as an anonymous array of two values, the first the minimum
scheduled time, the second the maximum scheduled time. If the first array item
is undefined, then the second will be considered the date that sched_time must
be less than. If the second array item is undefined, then the first will be
considered the date that sched_time must be greater than. If the value passed
in is undefined, then the query will specify 'IS NULL'. May also use C<ANY>
for a list of possible values.

=item comp_time

May pass in as an anonymous array of two values, the first the minimum
completion time, the second the maximum completion time. If the first array
item is undefined, then the second will be considered the date that sched_time
must be less than. If the second array item is undefined, then the first will
be considered the date that sched_time must be greater than. If the value
passed in is undefined, then the query will specify 'IS NULL'. May also use
C<ANY> for a list of possible values.

=item resource_id

A Bric::Dist::Resource object ID. May use C<ANY> for a list of possible
values.

=item server_type_id

A Bric::Dist::ServerType object ID. May use C<ANY> for a list of possible
values.

=item story_id

A story ID. May use C<ANY> for a list of possible values.

=item story_instance_id

A story instance ID. May use C<ANY> for a list of possible values.

=item media_id

A media ID. May use C<ANY> for a list of possible values.

=item media_instance_id

A media instance ID. May use C<ANY> for a list of possible values.

=item grp_id

A Bric::Util::Grp::Job object ID. May use C<ANY> for a list of possible
values.

=item failed

A boolean indicating whether or not a job is considered a failure. May use
C<ANY> for a list of possible values.

=item executing

A boolean indicating whether some process is running C<execute_me> on this
job.

=item type

A boolean indicating the type of the job. Pass true for an expiring job and
false for a publishing job.

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

B<Side Effects:> Populates each Bric::Util::Job object with data from the database
before returning them all.

B<Notes:> NONE.

=cut

sub list {
    my ($pkg, $params) = @_;
    my $class = ref $pkg || $pkg;
    $params->{_class_id} = $class->CLASS_ID unless $class eq __PACKAGE__;
    return wantarray ? @{ &$get_em($pkg, $params) } : &$get_em($pkg, $params);
}

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

=item my (@job_ids || $job_ids_aref) = Bric::Util::Job->list_ids($params)

Returns a list or anonymous array of Bric::Util::Job object IDs based on the
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

sub list_ids {
    my ($pkg, $params) = @_;
    my $class = ref $pkg || $pkg;
    $params->{_class_id} = $class->CLASS_ID unless $class eq __PACKAGE__;
    return wantarray
      ? @{ &$get_em($pkg, $params, 1) }
      : &$get_em($pkg, $params, 1);
}

################################################################################

=item $meths = Bric::Util::Job->my_meths

=item (@meths || $meths_aref) = Bric::Util::Job->my_meths(TRUE)

=item my (@meths || $meths_aref) = Bric::Util::Job->my_meths(0, TRUE)

Returns an anonymous hash of introspection data for this object. If called
with a true argument, it will return an ordered list or anonymous array of
introspection data. If a second true argument is passed instead of a first,
then a list or anonymous array of introspection data will be returned for
properties that uniquely identify an object (excluding C<id>, which is
assumed).

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
    my ($pkg, $ord, $ident) = @_;
    return if $ident;

    # Return 'em if we got em.
    return !$ord ? $meths : wantarray ? @{$meths}{@ORD} : [@{$meths}{@ORD}]
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
              priority   => {
                              name     => 'priority',
                              get_meth => sub { shift->get_priority(@_) },
                              get_args => [],
                              set_meth => sub { shift->set_priority(@_) },
                              set_args => [],
                              disp     => 'Priority',
                              len      => 1,
                              req      => 1,
                              type     => 'short',
                              props    => { type => 'select',
                                              vals => [[ 1 => 'High'],
                                                       [ 2 => 'Medium High'],
                                                       [ 3 => 'Normal'],
                                                       [ 4 => 'Medium Low'],
                                                       [ 5 => 'Low'], ],
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
              error_message => {
                              name     => 'error_message',
                              get_meth => sub { shift->get_error_message(@_) },
                              get_args => [],
                              set_meth => sub { shift->set_error_message(@_) },
                              set_args => [],
                              disp     => 'Error Message',
                              search   => 0,
                              req      => 0,
                              type     => 'short',
                              props    => { type      => 'textarea',
                                            cols      => 60,
                                            rows      => 10,
                                          }
                             },
             };
    return !$ord ? $meths : wantarray ? @{$meths}{@ORD} : [@{$meths}{@ORD}];
}

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item my $id = $job->get_id

Returns the ID of the Bric::Util::Job object.

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

B<Notes:> If the Bric::Util::Job object has been instantiated via the new()
constructor and has not yet been C<save>d, the object will not yet have an ID,
so this method call will return undef.

=item my $priority = $job->get_priority

Returns the priority of the Bric::Util::Job object.

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

=item $self = $job->set_priority($priority)

Sets the server type name.

B<Throws:> 

=over 4

=item *

Priority must be between 1 and 5 inclusive

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_priority {
    my ($self, $priority) = @_;
    &$check_priority($priority);
    $self->_set(['priority'] => [$priority]);
}

=item my $name = $job->get_name

Returns the name of the Bric::Util::Job object.

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

=item my $user_id = $job->get_user_id

Returns the user_id of the Bric::Util::Job object.

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

Cannot change scheduled time on executing job.

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
    throw_gen({ error => "Cannot change scheduled time on completed job." })
      if $self->_get('comp_time');
    throw_gen({ error => "Cannot change scheduled time on executing job." })
      if $self->_get('_executing');
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
    my $col = &$get_coll(shift, @RCOL_ARGS);
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

Cannot add resources to a executing job.

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
    throw_gen({ error => "Cannot add resources to a completed job." })
      if $self->_get('comp_time');
    throw_gen({ error => "Cannot add resources to a executing job." })
      if $self->_get('_executing');
    my $col = &$get_coll($self, @RCOL_ARGS);
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

Cannot delete resources from a executing job.

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
    throw_gen({ error => "Cannot delete resources from a completed job." })
      if $self->_get('comp_time');
    throw_gen({ error => "Cannot delete resources from a executing job." })
      if $self->_get('_executing');
    my $col = &$get_coll($self, @RCOL_ARGS);
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
    my $col = &$get_coll(shift, @SCOL_ARGS);
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

Cannot add server types to a executing job.

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
    throw_gen({ error => "Cannot add server types to a completed job." })
      if $self->_get('comp_time');
    throw_gen({ error => "Cannot add server types to a executing job." })
      if $self->_get('_executing');
    my $col = &$get_coll($self, @SCOL_ARGS);
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

Cannot delete server types from a executing job.

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
    throw_gen({ error => "Cannot delete server types from a completed job." })
      if $self->_get('comp_time');
    throw_gen({ error => "Cannot delete server types from a executing job." })
      if $self->_get('_executing');
    my $col = &$get_coll($self, @SCOL_ARGS);
    $col->del_objs(@_);
    $self->_set__dirty(1);
}

################################################################################

=item $self = $job->is_executing

Returns true ($self) if the job is executing (that is, in the process of being
executed), and undef it is not.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub is_executing { $_[0]->_get('_executing') ? $_[0] : undef }

################################################################################

=item $self = $job->has_failed

Returns true ($self) if the job threw an error on execution, returns false otherwise.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub has_failed { $_[0]->_get('_failed') ? 1 : 0 }

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

Cannot cancel executing job.

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
    throw_gen 'Cannot cancel completed job.' if $self->_get('_comp_time');
    throw_gen 'Cannot cancel executing job.' if $self->_get('_executing');
    $self->_set( ['_cancel'] => [1] );
}

################################################################################

=item $self = $job->reset

Resets the job. If it had failed, the error message will be reset to C<undef>
and the C<has_failed()> method will return false. Whether or not it has
failed, the number of tries will be reset to 0.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Cannot reset completed job.

=item *

Cannot reset executing job.

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

sub reset {
    my $self = shift;
    throw_gen 'Cannot reset completed job.'  if $self->_get('_comp_time');
    throw_gen 'Cannot cancel executing job.' if $self->_get('_executing');
    $self->_set( [qw(tries error_message _failed)], [0, undef, 0] );
}

################################################################################

=item $self = $job->save

Saves any changes to the Bric::Util::Job object. Returns $self on success and
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
        $res->save($id) if $res;
        $sts->save($id) if $sts;
    } elsif (defined $id) {
        # Existing record. Update it.
        local $" = ' = ?, '; # Simple way to create placeholders with an array.
        my $upd = prepare_c(qq{
            UPDATE job
            SET    @COLS = ?
            WHERE  id = ?
        });
        execute($upd, $self->_get(@PROPS), $id);
        $res->save($id) if $res;
        $sts->save($id) if $sts;
    } else {
        # It's a new job. Insert it.
        local $" = ', ';
        my $fields = join ', ', next_key('job'), ('?') x $#COLS;
        my $ins = prepare_c(qq{
            INSERT INTO job (@COLS)
            VALUES ($fields)
        }, undef, DEBUG);

        # Don't try to set ID - it will fail!
        my @ps = $self->_get(@PROPS[1..$#PROPS]);
        execute($ins, @ps);

        # Now grab the ID.
        $id = last_key('job');
        $self->_set(['id'] => [$id]);

        # Register this job in the "All Jobs" group and save any associated
        # destinations and resources.
        $self->register_instance(INSTANCE_GROUP_ID, GROUP_PACKAGE);
        $res->save($id) if $res;
        $sts->save($id) if $sts;

        # For simple deployments of Bricolage where the neither a job queue
        # nor a seperated dist machine are in use we want to execute *newly
        # inserted* jobs right away.
        if (ENABLE_DIST && !QUEUE_PUBLISH_JOBS
            && $self->get_sched_time('epoch') <= time)
        {
            # Execute the job and then be sure to start a new transaction!
            $self->execute_me;
            begin(1);
        }

    }
    return $self->SUPER::save;
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
    throw_gen({ error => "Cannot execute job before its scheduled time."})
      if $self->get_sched_time('epoch') > time;
    throw_gen({ error => "Cannot execute job that has already been executed."})
      if $self->get_comp_time;

    # Get a lock on the job or just return (because another process is likely
    # executing the job).
    $set_executing->($self, 1) or return;

    # Do it!
    eval {
        begin(1);
        $self->_do_it(@_);
        # Success!
        $self->_set([qw(comp_time _executing)] => [db_date(0, 1), 0]);
        $self->save;
        log_event('job_exec', $self);
        commit_events();
        commit(1);
    };

    if (my $err = $@) {
        # Rollback and handle.
        rollback(1);
        $self->handle_error($err);
    }
    return $self;
}

################################################################################

=item $self = $job->handle_error($msg)

Concatinates the msg to the I<top> of the error_message field.  After
Bric::Config::DIST_ATTEMPTS it also marks the Job as having failed.

=cut

sub handle_error {
    my ($self, $err) = @_;
    if ($self->get_id) {
        begin(1);
        # Convert the error to text
        if ($self->_get('tries') >= DIST_ATTEMPTS) {
            # We've met or exceeded the maximum number of attempts. Save
            # the error message and mark the job as failed, and no longer
            # executing.
            $self->_set([qw(_executing error_message _failed)], [0, "$err", 1]);
            # Log the failure. It's okay that it logs for the user executing
            # the job rather than the user who scheduled it.
            log_event( $self->KEY_NAME . '_failed', $self);
        } else {
            # We're gonna try again. Unlock the job.
            $self->_set([qw(_executing error_message)], [0, "$err"]);
        }
        $self->save;
        commit(1);
    } else {
        # The job hasn't been added to the database, yet. Save the error;
        # save() will catch it and rethrow it.
        $self->_set([qw(_executing error_message)] => [0, "$err"]);
    }

    die $err;  # now re-throw the error that got us here
}

################################################################################

=back

=head1 PRIVATE

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

=over 4

=item $job = $job->_do_it

This is an abstract method that must be implemented in subclasses. In
subclasses, C<_do_it()> carries out the tasks that constitute a job. Here in
the base class, it throws an exception.

=cut

sub _do_it { throw_mni ref(shift()) . '->_do_it not implemented' }

##############################################################################

=back

=head2 Private Functions

=over 4

=item my $_aref = &$get_em( $pkg, $params )

=item my $_ids_aref = &$get_em( $pkg, $params, 1 )

Function used by lookup() and list() to return a list of Bric::Util::Job objects
or, if called with an optional third argument, returns a listof Bric::Util::Job
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
    my $tables = 'job a, member m, job_member c';
    my $wheres = 'a.id = c.object_id AND m.id = c.member__id AND ' .
      "m.active = '1'";
    my @params;
    my %map = (
        id                => 'a.id = ?',
        _class_id         => 'a.class__id = ?',
        media_instance_id => 'a.media_instance__id = ?',
        story_instance_id => 'a.story_instance__id = ?',
        user_id           => 'a.usr__id = ?',
        name              => 'LOWER(a.name) LIKE LOWER(?)',
        error_message     => 'LOWER(a.error_message) LIKE LOWER(?)',
    );

    my %bool = (
        type      => 'a.expire = ?',
        failed    => 'a.failed = ?',
        executing => 'a.executing = ?',
    );

    while (my ($k, $v) = each %$params) {
        if ($map{$k}) {
            $wheres .= ' AND ' . any_where $v, $map{$k}, \@params;
        }

        elsif ($bool{$k}) {
            $wheres .= ' AND '
                    . any_where( ($v ? 1 : 0), $bool{$k}, \@params );
        }

        elsif ($k eq 'server_type_id') {
            # Add job__server_type to the lists of tables and join to it.
            $tables .= ', job__server_type js';
            $wheres .= ' AND a.id = js.job__id AND '
                    . any_where $v, 'js.server_type__id = ?', \@params;
        }

        elsif ($k eq 'story_id') {
            # Add story_instance to the lists of tables and join to it.
            $tables .= ', story_instance si';
            $wheres .= ' AND a.story_instance__id = si.id AND '
                    . any_where $v, 'si.story__id = ?', \@params;
        }

        elsif ($k eq 'media_id') {
            # Add media_instance to the lists of tables and join to it.
            $tables .= ', media_instance mi';
            $wheres .= ' AND a.media_instance__id = mi.id AND '
                    . any_where $v, 'mi.media__id = ?', \@params;
        }

        elsif ($k eq 'resource_id') {
            # Add job__resource to the lists of tables and join to it.
            $tables .= ', job__resource jr';
            $wheres .= ' AND a.id = jr.job__id AND '
                    . any_where $v, 'jr.resource__id = ?', \@params;
        }

        elsif ($k eq 'grp_id') {
            # Add in the group tables a second time and join to them.
            $tables .= ', member m2, job_member c2';
            $wheres .= ' AND a.id = c2.object_id AND c2.member__id = m2.id'
                    . " AND m2.active = '1' AND "
                    . any_where $v, 'm2.grp__id = ?', \@params;
        }

        else {
            # It's a date column.
            if (blessed $v) {
                db_date($_) for @$v;
                $wheres .= ' AND ' . any_where $v, "a.$k = ?", \@params;
            }

            elsif (ref $v) {
                # It's an arrayref of dates.
                if (!defined $v->[0]) {
                    # It's less than.
                    $wheres .= " AND a.$k < ?";
                    push @params, db_date($v->[1]);
                } elsif (!defined $v->[1]) {
                    # It's greater than.
                    $wheres .= " AND a.$k > ?";
                    push @params, db_date($v->[0]);
                } else {
                    # It's between two sizes.
                    $wheres .= " AND $k BETWEEN ? AND ?";
                    push @params, (db_date($v->[0]), db_date($v->[1]));
                }
            } elsif (!defined $v) {
                # It needs to be null.
                $wheres .= " AND a.$k IS NULL";
            } else {
                # It's a single value.
                $wheres .= ' AND '
                        . any_where db_date($v), "a.$k = ?", \@params;
            }
        }
    }

    # Assemble and prepare the query.
    my ($qry_cols, $order) = $ids ? (\'DISTINCT a.id', 'a.id')
                                  : (\$SEL_COLS, 'a.priority, a.sched_time, a.id')
                                  ;

    my $sel = prepare_c(qq{
        SELECT $$qry_cols
        FROM   $tables
        WHERE  $wheres
        ORDER BY $order
    }, undef, DEBUG);

    # Just return the IDs, if they're what's wanted.
    return col_aref($sel, @params) if $ids;

    execute($sel, @params);
    my (@d, @jobs, $grp_ids);
    bind_columns($sel, \@d[0..$#SEL_PROPS]);
    my $last = -1;
    $pkg = ref $pkg || $pkg;
    while (fetch($sel)) {
        if ($d[0] != $last) {
            $last = $d[0];
            # Create a new job object.
            my $self = bless {}, $pkg;
            $self->SUPER::new;
            # Get a reference to the array of group IDs.
            $grp_ids = $d[$#d] = [$d[$#d]];
            $self->_set(\@SEL_PROPS, \@d);
            bless $self, $PKG_MAP->{$self->_get('_class_id')};
            $self->_set__dirty; # Disables dirty flag.
            push @jobs, $self;
        } else {
            push @$grp_ids, $d[$#d];
        }
    }
    return \@jobs;
};

##############################################################################

=item my $coll = $get_coll->($self, $class, $key)

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

##############################################################################

=item my $bool = $check_priority->($priority)

Checks a number to see if it is in the correct range for a priority
setting (1 to 5, inclusive), and throws an error if it isn't.

=cut

$check_priority = sub {
    throw_gen "Priority must be between 1 and 5 inclusive."
      unless $_[0] >= 1 && $_[0] <= 5;
};

##############################################################################

=item my $bool = $set_executing->($self, $value)

Sets the executing column in the database, as well as the executing property
in the job object. Used by C<execute_me()>.

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

$set_executing = sub {
    my ($self, $value) = @_;
    my ($id, $exec) = $self->_get(qw(id tries));
    $exec++ if $value;
    my $ret;
    eval {
        begin(1);
        my $upd = prepare_c(qq{
            UPDATE job
            SET    executing = ?,
                   tries = ?
            WHERE  id = ?
                   AND executing <> ?
        });

        $ret = execute($upd, $value, $exec, $id, $value);
        # Commit the transaction so that no other processes will attempt to
        # execute the job.
        commit(1);
    };

    # Handle any exceptions.
    if (my $err = $@) {
        rollback(1);
        die $err;
    }

    # Output a warning if we couldn't get a lock.
    if ($ret eq '0E0') {
        print STDERR "Can't get a lock on job No. ". $self->get_id . ".\n";
        return;
    }

    # Set the new number of tries and the executing attribute and return.
    return $self->_set([qw(_executing tries)], [$value, $exec]);
};

1;
__END__

=back

=head1 NOTES

NONE.

=head1 AUTHORS

David Wheeler <david@justatheory.com>

Mark Jaroski <jaroskim@who.int>

=head1 SEE ALSO

L<Bric|Bric>,
L<Bric::Dist::Resource|Bric::Dist::Resource>,
L<Bric::Dist::ServerType|Bric::Dist::ServerType>

=cut
