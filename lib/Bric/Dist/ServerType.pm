package Bric::Dist::ServerType;

=head1 NAME

Bric::Dist::ServerType - Interface for managing types of servers to which to
distribute content.

=head1 VERSION

$Revision: 1.6 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.6 $ )[-1];

=head1 DATE

$Date: 2002-01-06 04:40:36 $

=head1 SYNOPSIS

  use Bric::Dist::ServerType;

  # Constructors.
  # Create a new object.
  my $st = Bric::Dist::ServerType->new;
  # Look up an existing object.
  $st = Bric::Dist::ServerType->lookup({ id => 1 });
  # Get a list of server type objects.
  my @servers = Bric::Dist::ServerType->list(
    { move_method => 'FTP Transport' });
  # Get an anonymous hash of server type objects.
  my $sts_href = Bric::Dist::ServerType->href({ description => 'Preview%' });

  # Class methods.
  # Get a list of object IDs.
  my @st_ids = Bric::Dist::ServerType->list_ids({ description => 'Preview%' });
  # Get an introspection hashref.
  my $int = Bric::Dist::ServerType->my_meths;
  # Get a list of mover types.
  my @move_methods = Bric::Dist::ServerType->list_move_methods;

  # Instance Methods.
  my $id = $st->get_id;
  my $name = $st->get_name;
  $st = $st->set_name($name);
  my $description = $st->get_description;
  $st = $st->set_description($description);
  my $move_method = $st->get_move_method;
  $st = $st->set_move_method($move_method);

  print "ST is ", $st->can_copy ? '' : 'not ', "copyable.\n";
  $st->copy;
  $st->no_copy;

  print "ST ", $st->can_publish ? 'publishes' : 'does not publish.\n";
  $st = $st->on_publish; # Used for publish event.
  $st = $st->no_publish; # Not used for publish event.

  print "ST ", $st->can_preview ? 'previews' : 'does not preview.\n";
  $st = $st->on_preview; # Used for preview event.
  $st = $st->no_preview; # Not used for preview event.

  print "ST is ", $st->is_active ? '' : 'not ', "active.\n";
  $st->deactivate;
  $st->activate;

  # Accessors to servers of this type.
  my @servers = $st->get_servers;
  my $server = $st->new_server;
  $st->del_servers;

  # Accessors to output channels associated with this server type.
  my @ocs = $job->get_output_channels;
  $st = $st->add_output_channels(@ocs);
  $st = $st->del_output_channels(@ocs);

  # Accessors to actions associated with this type.
  my @actions = $st->get_actions;
  my $action = $st->new_action;
  $st->del_actions;

  # Save it.
  $st->save;

=head1 DESCRIPTION

This class manages types of servers. A server type represents a class of
servers on which a list of actions should be performed upon the execution of
a job. A server type, therefore, simply describes a list of servers for which
the actions will be performed and a list of actions to be executed on the files
associated with a given job. The last action should be a move statement, to
move each file to each of the servers.

So use this class a the central management point for figuring out what happens
to files, and in what order, and what servers they are sent to, in the event
of a publish or preview event.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Util::DBI qw(:all);
use Bric::Util::Coll::Server;
use Bric::Util::Coll::Action;
use Bric::Util::Coll::OutputChannel;
use Bric::Util::Fault::Exception::DP;
use Bric::Util::Grp::Dest;

################################################################################
# Inheritance
################################################################################
use base qw(Bric);

################################################################################
# Function and Closure Prototypes
################################################################################
my ($get_em, $get_coll);

################################################################################
# Constants
################################################################################
use constant DEBUG => 0;
use constant GROUP_PACKAGE => 'Bric::Util::Grp::Dest';
use constant INSTANCE_GROUP_ID => 29;

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields
my @cols = qw(s.id s.name s.description s.copyable s.publish s.preview s.active
	      c.disp_name c.pkg_name);
my @props = qw(id name description _copy _publish _preview _active move_method
	       _mover_class);
my @scols = qw(id name description copyable publish preview active);
my @scol_args = ('Bric::Util::Coll::Server', '_servers');
my @acol_args = ('Bric::Util::Coll::Action', '_actions');
my @ocol_args = ('Bric::Util::Coll::OutputChannel', '_ocs');
my %num_map = ( id => 's.id = ?',
		job_id => "s.id IN (SELECT server_type__id FROM "
                          . "job__server_type WHERE job__id = ?)",
		output_channel_id => "s.id IN (SELECT server_type__id FROM "
	                  . "server_type__output_channel "
		          . "WHERE output_channel__id = ?)");

my %bool_map = ( can_copy => 's.copyable = ?',
		 can_publish => 's.publish = ?',
		 can_preview => 's.preview = ?');
my @ord = qw(name description move_method copy publish preview active);
my $meths;

################################################################################

################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({
			 # Public Fields
			 id => Bric::FIELD_READ,
			 name => Bric::FIELD_RDWR,
			 description => Bric::FIELD_RDWR,
			 move_method => Bric::FIELD_RDWR,

			 # Private Fields
			 _mover_class => Bric::FIELD_NONE,
			 _copy => Bric::FIELD_NONE,
			 _active => Bric::FIELD_NONE,
			 _servers => Bric::FIELD_NONE,
			 _actions => Bric::FIELD_NONE,
			 _publish => Bric::FIELD_NONE,
			 _preview => Bric::FIELD_NONE
			});
}

################################################################################
# Class Methods
################################################################################

=head1 INTERFACE

=head2 Constructors

=over 4

=item my $st = Bric::Dist::ServerType->new($init)

Instantiates a Bric::Dist::ServerType object. An anonymous hash of initial values may be
passed. The supported initial value keys are:

=over 4

=item *

name

=item *

description

=item *

move_method

=back

The active property will be set to true and the copy property to false by
default. Call $st->save() to save the new object.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub new {
    my ($pkg, $init) = @_;
    my $self = ref $pkg || $pkg;
    @{$init}{qw(_active _publish _preview _copy)} = (1, 1, 0, 0);
    $self->SUPER::new($init);
}

################################################################################

=item my $st = Bric::Dist::ServerType->lookup({ id => $id })

=item my $st = Bric::Dist::ServerType->lookup({ name => $name })

Looks up and instantiates a new Bric::Dist::ServerType object based on the
Bric::Dist::ServerType object ID or name passed. If $id or $name is not found in
the database, lookup() returns undef.

B<Throws:>

=over

=item *

Too many Bric::Dist::ServerType objects found.

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

B<Side Effects:> If $id is found, populates the new Bric::Dist::ServerType object
with data from the database before returning it.

B<Notes:> NONE.

=cut

sub lookup {
    my $st = &$get_em(@_);
    # We want @$st to have only one value.
    die Bric::Util::Fault::Exception::DP->new({
      msg => 'Too many Bric::Dist::ServerType objects found.' }) if @$st > 1;
    return @$st ? $st->[0] : undef;
}

################################################################################

=item my (@sts || $sts_aref) = Bric::Dist::ServerType->list($params)

Returns a list or anonymous array of Bric::Dist::ServerType objects based on the
search parameters passed via an anonymous hash. The supported lookup keys are:

=over 4

=item *

move_method

=item *

description

=item *

job_id

=item *

output_channel_id

=item *

can_copy

=item *

can_publish

=item *

can_preview

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

B<Side Effects:> Populates each Bric::Dist::ServerType object with data from the
database before returning them all.

B<Notes:> NONE.

=cut

sub list { wantarray ? @{ &$get_em(@_) } : &$get_em(@_) }

################################################################################

=item my $sts_href = Bric::Dist::ServerType->href($params)

Returns an anonymous hash of Bric::Dist::ServerType objects, where the keys are
object IDs and the values or the objects themselves,  based on the
search parameters passed via an anonymous hash. The supported lookup keys are
are the same as for list().

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

B<Side Effects:> Populates each Bric::Dist::ServerType object with data from the
database before returning them all.

B<Notes:> NONE.

=cut

sub href { &$get_em(@_, 0, 1) }

################################################################################

=back 4

=head2 Destructors

=over 4

=item $st->DESTROY

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

=item my (@st_ids || $st_ids_aref) = Bric::Dist::ServerType->list_ids($params)

Returns a list or anonymous array of Bric::Dist::ServerType object IDs based on
the search criteria passed via an anonymous hash. The supported lookup keys are
the same as those for list().

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

=item my (@types || $types_aref) = Bric::Dist::ServerType->list_move_methods

Returns a list or anonymous array of the names of classes that feature a method
to move resources.

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select column into arrayref.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub list_move_methods {
    my $sel = prepare_ca(qq{
        SELECT disp_name
        FROM   class
        WHERE  distributor = 1
    });
    return wantarray ? @{ col_aref($sel) } : col_aref($sel);
}

################################################################################

=item $meths = Bric::Dist::ServerType >my_meths

=item (@meths || $meths_aref) = Bric::Dist::ServerType->my_meths(TRUE)

Returns an anonymous hash of instrospection data for this object. If called with
a true argument, it will return an ordered list or anonymous array of
intrspection data. The format for each introspection item introspection is as
follows:

Each hash key is the name of a property or attribute of the object. The value
for a hash key is another anonymous hash containing the following keys:

=over 4

=item *

name - The name of the property or attribute. Is the same as the hash key when
an anonymous hash is returned.

=item *

disp - The display name of the property or attribute.

=item *

get_meth - A reference to the method that will retrieve the value of the
property or attribute.

=item *

get_args - An anonymous array of arguments to pass to a call to get_meth in
order to retrieve the value of the property or attribute.

=item *

set_meth - A reference to the method that will set the value of the
property or attribute.

=item *

set_args - An anonymous array of arguments to pass to a call to set_meth in
order to set the value of the property or attribute.

=item *

type - The type of value the property or attribute contains. There are only
three types:

=over 4

=item short

=item date

=item blob

=back

=item *

len - If the value is a 'short' value, this hash key contains the length of the
field.

=item *

search - The property is searchable via the list() and list_ids() methods.

=item *

req - The property or attribute is required.

=item *

props - An anonymous hash of properties used to display the property or attribute.
Possible keys include:

=over 4

=item *

type - The display field type. Possible values are

=item text

=item textarea

=item password

=item hidden

=item radio

=item checkbox

=item select

=back

=item *

length - The Length, in letters, to display a text or password field.

=item *

maxlength - The maximum length of the property or value - usually defined by the
SQL DDL.

=item *

rows - The number of rows to format in a textarea field.

=item

cols - The number of columns to format in a textarea field.

=item *

vals - An anonymous hash of key/value pairs reprsenting the values and display
names to use in a select list.

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

    my $move_methods = list_move_methods();
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
			      req      => 0,
			      type     => 'short',
			      props    => { type      => 'text',
					    length    => 32,
					    maxlength => 64
					  }
			     },
	      description => {
			      name     => 'description',
			      get_meth => sub { shift->get_description(@_) },
			      get_args => [],
			      set_meth => sub { shift->set_description(@_) },
			      set_args => [],
			      disp     => 'Description',
			      len      => 256,
			      req      => 0,
			      type     => 'short',
			      props    => { type => 'textarea',
					    cols => 40,
					    rows => 4
					  }
			     },
	      move_method => {
			      name     => 'move_method',
			      get_meth => sub { shift->get_move_method(@_) },
			      get_args => [],
			      set_meth => sub { shift->set_move_method(@_) },
			      set_args => [],
			      disp     => 'Move Method',
			      len      => 128,
			      req      => 0,
			      type     => 'short',
			      props    => {   type => 'select',
					      vals => $move_methods
					  }
			     },
	      copy     =>   {
			     name     => 'copy',
			     get_meth => sub { shift->can_copy(@_) ? 1 : 0 },
			     get_args => [],
			     set_meth => sub { $_[1] ? shift->copy(@_)
						 : shift->no_copy(@_) },
			     set_args => [],
			     disp     => 'Copy Resources',
			     len      => 1,
			     req      => 1,
			     type     => 'short',
			     props    => { type => 'checkbox' }
			    },
	      publish    => {
			     name     => 'publish',
			     get_meth => sub { shift->can_publish(@_) ? 1 : 0 },
			     get_args => [],
			     set_meth => sub { $_[1] ? shift->on_publish(@_)
						 : shift->no_publish(@_) },
			     set_args => [],
			     disp     => 'Publishes',
			     len      => 1,
			     req      => 1,
			     type     => 'short',
			     props    => { type => 'checkbox' }
			    },
	      preview   => {
			     name     => 'preview',
			     get_meth => sub { shift->can_preview(@_) ? 1 : 0 },
			     get_args => [],
			     set_meth => sub { $_[1] ? shift->on_preview(@_)
						 : shift->no_preview(@_) },
			     set_args => [],
			     disp     => 'Previews',
			     len      => 1,
			     req      => 1,
			     type     => 'short',
			     props    => { type => 'checkbox' }
			    },
	      active     => {
			     name     => 'active',
			     get_meth => sub { shift->is_active(@_) ? 1 : 0 },
			     get_args => [],
			     set_meth => sub { $_[1] ? shift->activate(@_)
						 : shift->deactivate(@_) },
			     set_args => [],
			     disp     => 'Active',
			     len      => 1,
			     req      => 1,
			     type     => 'short',
			     props    => { type => 'checkbox' }
			    },
	     };
    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}];
}

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item my $id = $st->get_id

Returns the ID of the Bric::Dist::ServerType object.

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

B<Notes:> If the Bric::Dist::ServerType object has been instantiated via the new()
constructor and has not yet been C<save>d, the object will not yet have an ID,
so this method call will return undef.

=item my $name = $st->get_name

Returns the server type name.

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

Sets the server type name. The name must be unique.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'name' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $description = $st->get_description

Returns the server type description.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'description' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $st->set_description($description)

Sets the server type description.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'description' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $move_method = $st->get_move_method

Returns the display name of the Bricolage class responible for moving resources to
servers of this type.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'move_method' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $st->set_move_method($move_method)

Sets the name of the class responible for moving resources to servers of this
type. Get a list of supporte mover types from list_move_methods().

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'move_method' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my (@ocs || $ocs_aref) = $job->get_output_channels

=item my (@ocs || $ocs_aref) = $job->get_output_channels(@oc_ids)

Returns a list or anonymous array of the Bric::Biz::OutputChannel objects that
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

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_output_channels {
    my $col = &$get_coll(shift, @ocol_args);
    $col->get_objs(@_);
}

################################################################################

=item $job = $job->add_output_channels(@ocs)

Adds Output Channels to this job. Call save() to save the relationship. Output
Channels cannot be added to a job after the job has executed. Trying to add
Output Channels after a job has completed will throw an exception.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::Coll::Server internally.

=cut

sub add_output_channels {
    my $self = shift;
    my $col = &$get_coll($self, @ocol_args);
    $col->add_new_objs(@_);
    $self->_set__dirty(1);
}

################################################################################

=item $self = $job->del_output_channels(@ocs)

Dissociates Output Channels, represented as Bric::Biz::OutputChannel objects, from the job.
call save() to save the dissociations to the database.

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

sub del_output_channels {
    my $self = shift;
    my $col = &$get_coll($self, @ocol_args);
    $col->del_objs(@_);
    $self->_set__dirty(1);
}

################################################################################

=item my (@servers || $servers_aref) = $st->get_servers(@server_ids)

Returns a list or anonymous array of Bric::Dist::Server objects that are of this
type. Pass in a list of Bric::Dist::Server object IDs to get back only those
Bric::Dist::Server objects. If no IDs are passed, all the Bric::Dist::Server objects
of this type will be returned.

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

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::Coll::Server internally.

=cut

sub get_servers {
    my $col = &$get_coll(shift, @scol_args);
    $col->get_objs(@_);
}

=item my $server = $st->new_server($init)

Adds a new server to this server type. The initial values for the $init
anonymous hash are the same as those for Bric::Dist::Server->new(), although the
server_type_id property will be set automatically to associate the new server
object with this server type.

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

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::Coll::Server internally.

=cut

sub new_server {
    my ($self, $init) = @_;
    $init->{server_type_id} = $self->_get('id');
    my $col = &$get_coll($self, @scol_args);
    $col->new_obj($init);
}

=item $self = $st->del_servers(@server_ids)

Deletes Bric::Dist::Server objects from this type. Pass in a list of
Bric::Dist::Server object IDs to delete only those servers. If no IDs are passed,
all of the Bric::Dist::Server objects of this type will be deleted.

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

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::Coll::Server internally.

=cut

sub del_servers {
    my $col = &$get_coll(shift, @scol_args);
    $col->del_objs(@_);
}

################################################################################

=item my (@actions || $actions_aref) = $st->get_actions(@action_ids)

Returns a list or anonymous array of Bric::Dist::Action objects that are of this
type. Pass in a list of Bric::Dist::Action object IDs to get back only those
Bric::Dist::Action objects. If no IDs are passed, all the Bric::Dist::Action objects
of this type will be returned.

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

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::Coll::Action internally.

=cut

sub get_actions {
    my $col = &$get_coll(shift, @acol_args);
    $col->get_objs(@_);
}

=item my $action = $st->new_action($init)

Adds a new action to this action type. The initial values for the $init
anonymous hash are the same as those for Bric::Dist::Action->new(), although the
server_type_id property will be set automatically to associate the new action
object with this server type.

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

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::Coll::Action internally.

=cut

sub new_action {
    my ($self, $init) = @_;
    $init->{server_type_id} = $self->_get('id');
    my $col = &$get_coll($self, @acol_args);
    $col->new_obj($init);
}

=item $self = $st->del_actions(@action_ids)

Deletes Bric::Dist::Action objects from this type. Pass in a list of
Bric::Dist::Action object IDs to delete only those actions. If no IDs are passed,
all of the Bric::Dist::Action objects of this type will be deleted.

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

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::Coll::Action internally.

=cut

sub del_actions {
    my $col = &$get_coll(shift, @acol_args);
    $col->del_objs(@_);
}

################################################################################

=item $self = $st->copy

Sets the copy property to true, meaning that when a job is executed for this
server type, all the resources should be copied to a temporary directory before
the actions are applied to them.

B<Throws:>

=over 4

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub copy { $_[0]->_set({_copy => 1 }) }

=item $self = $st->no_copy

Sets the copy property to false, meaning that when a job is executed for this
server type, all the resources will have the actions applied to them in place,
without first moving them to a temporary directory.

B<Throws:>

=over 4

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub no_copy { $_[0]->_set({_copy => 0 }) }

=item $self = $st->can_copy

Returns $self if the resources should be copied to a temporary directory before
performing actions on them, and false if the actions can be applied to the
resources in place.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub can_copy { $_[0]->_get('_copy') ? $_[0] : undef }

################################################################################

=item $self = $st->on_publish

Sets the copy publish to true, meaning that this server type should be used for
publish events.

B<Throws:>

=over 4

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub on_publish { $_[0]->_set({_publish => 1 }) }

=item $self = $st->no_publish

Sets the publish property to false, meaning that this server type should be used
for jobs triggered by publish events.

B<Throws:>

=over 4

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub no_publish { $_[0]->_set({_publish => 0 }) }

=item $self = $st->can_publish

Returns $self if this server type is used to move files for a publish event.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub can_publish { $_[0]->_get('_publish') ? $_[0] : undef }

################################################################################

=item $self = $st->on_preview

Sets the copy preview to true, meaning that this server type should be used for
preview events.

B<Throws:>

=over 4

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub on_preview { $_[0]->_set({_preview => 1 }) }

=item $self = $st->no_preview

Sets the preview property to false, meaning that this server type should be used
for jobs triggered by preview events.

B<Throws:>

=over 4

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub no_preview { $_[0]->_set({_preview => 0 }) }

=item $self = $st->can_preview

Returns $self if this server type is used to move files for a preview event.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub can_preview { $_[0]->_get('_preview') ? $_[0] : undef }

################################################################################

=item $self = $st->activate

Activates the Bric::Dist::ServerType object. Call $st->save to make the change
persistent. Bric::Dist::ServerType objects instantiated by new() are active by
default.

B<Throws:>

=over 4

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub activate {
    my $self = shift;
    $self->_set({_active => 1 });
}

=item $self = $st->deactivate

Deactivates (deletes) the Bric::Dist::ServerType object. Call $st->save to make
the change persistent.

B<Throws:>

=over 4

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub deactivate {
    my $self = shift;
    $self->_set({_active => 0 });
}

=item $self = $st->is_active

Returns $self if the Bric::Dist::ServerType object is active, and undef if it is not.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub is_active {
    my $self = shift;
    $self->_get('_active') ? $self : undef;
}

################################################################################

=item $self = $st->save

Saves any changes to the Bric::Dist::ServerType object. Returns $self on success
and undef on failure.

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
    my $dirt = $self->_get__dirty;
    my ($id, $servers, $actions, $ocs) = $self->_get(qw(id _servers _actions _ocs));
    if (defined $id && $dirt) {
	# It's an existing record. Update it.
	local $" = ' = ?, '; # Simple way to create placeholders with an array.
	my $upd = prepare_c(qq{
            UPDATE server_type
            SET    @scols = ?,
                   class__id = (SELECT id FROM class WHERE LOWER(disp_name) = LOWER(?))
            WHERE  id = ?
        }, undef, DEBUG);
	execute($upd, $self->_get(@props[0..$#props -1]), $id);
    } elsif ($dirt) {
	# It's a new resource. Insert it.
	local $" = ', ';
	my $fields = join ', ', next_key('server_type'), ('?') x $#scols;
	my $ins = prepare_c(qq{
            INSERT INTO server_type (@scols, class__id)
            VALUES ($fields, (SELECT id FROM class WHERE LOWER(disp_name) = LOWER(?)))
        }, undef, DEBUG);
	# Don't try to set ID - it will fail!
	execute($ins, $self->_get(@props[1..$#props - 1]));
	# Now grab the ID.
	$id = last_key('server_type');
	$self->_set(['id'], [$id]);

	# And finally, register this person in the "All Destinations" group.
	$self->register_instance(INSTANCE_GROUP_ID, GROUP_PACKAGE);
    }

    # Okay, now save any changes to associated servers and actions.
    $servers->save($id) if $servers;
    $actions->save($id) if $actions;
    $ocs->save($id) if $ocs;
    $self->SUPER::save;
    return $self;
}

################################################################################

=back 4

=head1 PRIVATE

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

=item my $mover_class = $st->_get_mover_class()

Returns the Class (package) name of the class used to move resources. Used by
Bric::Dist::Action::Mover so that it knows who to tell to do the moving.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> If the move method has been changed via set_move_method() since
the current object was instantiated, this method will return the old package
name rather than the new one. To get the new one, instantiate the object but
don't change its method. If you really want to change it, do so, save it, and
then re-instantiate it via Bric::Dist::ServerType->lookup().

B<Notes:> NONE>

=cut

sub _get_mover_class { $_[0]->_get('_mover_class') }

=head2 Private Functions

=over 4

=item my $st_aref = &$get_em( $pkg, $params )

=item my $st_ids_aref = &$get_em( $pkg, $params, 1 )

Function used by lookup() and list() to return a list of Bric::Dist::ServerType objects
or, if called with an optional third argument, returns a listof Bric::Dist::ServerType
object IDs (used by list_ids()).

Function used by lookup() and list() to return a list of Bric::Dist::Resource
objects or, if called with an optional third argument, returns a listof
Bric::Dist::Resource object IDs (used by list_ids()).

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

B<Notes:>

=cut

$get_em = sub {
    my ($pkg, $params, $ids, $href) = @_;
    my (@wheres, @params);
    while (my ($k, $v) = each %$params) {
	if ($num_map{$k}) {
	    push @wheres, $num_map{$k};
	    push @params, $v;
	} elsif ($bool_map{$k}) {
	    push @wheres, $bool_map{$k};
	    push @params, $v ? 1 : 0;
	} elsif ($k eq 'move_method') {
	    push @wheres, "LOWER(c.disp_name) LIKE ?";
	    push @params, lc $v;
	} else {
	    push @wheres, "LOWER(s.$k) LIKE ?";
	    push @params, lc $v;
	}
    }

    # Assemble the WHERE clause.
    my $where = $params->{id} ? '' : "\n               AND active = 1";
    $where .= "\n               AND " . join ' AND ', @wheres if @wheres;

    # Assemble and prepare the query.
    local $" = ', ';
    my $qry_cols = $ids ? ['s.id'] : \@cols;
    my $sel = prepare_c(qq{
        SELECT @$qry_cols
        FROM   server_type s, class c
        WHERE  s.class__id = c.id $where
        ORDER BY s.name
    }, undef, DEBUG);

    # Just return the IDs, if they're what's wanted.
    return col_aref($sel, @params) if $ids;

    # Grab all the records.
    execute($sel, @params);
    my (@d, @sts, %sts);
    bind_columns($sel, \@d[0..$#cols]);
    $pkg = ref $pkg || $pkg;
    while (fetch($sel)) {
	# Create a new object for each row.
	my $self = bless {}, $pkg;
	$self->SUPER::new;
	$self->_set(\@props, \@d);
	$self->_set__dirty; # Disables dirty flag.
	$href ? $sts{$d[0]} = $self : push @sts, $self
    }
    finish($sel);
    # Return the objects.
    return $href ? \%sts : \@sts;
};

=item my $rules = &$get_coll($self, $class, $key)

Returns the collection of objects stored under $key in $self. The collection is
a subclass Bric::Util::Coll object, identified by $class. See Bric::Util::Coll for
interface details.

B<Throws:>

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
    $coll = $class->new({server_type_id => $id});
    $self->_set([$key], [$coll]);
    $self->_set__dirty; # Unset the dirty flag.
    return $coll;
};

1;
__END__

=back

=head1 NOTES

NONE.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

L<Bric|Bric>

=cut
