package Bric::Dist::ServerType;

=head1 Name

Bric::Dist::ServerType - Interface for managing types of servers to which to
distribute content.

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::Dist::ServerType;

  # Constructors.
  # Create a new object.
  my $st = Bric::Dist::ServerType->new;
  # Look up an existing object.
  $st = Bric::Dist::ServerType->lookup({ id => 1 });
  # Get a list of server type objects.
  my @sts = Bric::Dist::ServerType->list({ move_method => 'FTP Transport' });
  # Get an anonymous hash of server type objects.
  my $sts_href = Bric::Dist::ServerType->href({ description => 'Preview%' });

  # Class methods.
  # Get a list of object IDs.
  my @st_ids = Bric::Dist::ServerType->list_ids({ description => 'Prev%' });
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
  my $site_id = $st->get_site_id;
  $st = $st->set_site_id($site_id);
  print "ST is ", $st->can_copy ? '' : 'not ', "copyable.\n";
  $st->copy;
  $st->no_copy;

  print "ST ", $st->can_publish ? 'publishes' : "does not publish.\n";
  $st = $st->on_publish; # Used for publish event.
  $st = $st->no_publish; # Not used for publish event.

  print "ST ", $st->can_preview ? 'previews' : "does not preview.\n";
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
  my @ocs = $st->get_output_channels;
  $st = $st->add_output_channels(@ocs);
  $st = $st->del_output_channels(@ocs);

  # Accessors to actions associated with this type.
  my @actions = $st->get_actions;
  my $action = $st->new_action;
  $st->del_actions;

  # Save it.
  $st->save;

=head1 Description

This class manages types of servers. A server type represents a class of
servers on which a list of actions should be performed upon the execution of a
job. A server type, therefore, simply describes a list of servers for which
the actions will be performed and a list of actions to be executed on the
files associated with a given job. The last action should be a move statement,
to move each file to each of the servers.

So use this class a the central management point for figuring out what happens
to files, and in what order, and what servers they are sent to, in the event
of a publish or preview event.

=cut

##############################################################################
# Dependencies
##############################################################################
# Standard Dependencies
use strict;

##############################################################################
# Programmatic Dependences
use Bric::Util::DBI qw(:all);
use Bric::Util::Coll::Server;
use Bric::Util::Coll::Action;
use Bric::Util::Coll::OutputChannel;
use Bric::Util::Fault qw(throw_dp);
use Bric::Util::Grp::Dest;
use Bric::Config qw(:dist);

##############################################################################
# Inheritance
##############################################################################
use base qw(Bric);

##############################################################################
# Function and Closure Prototypes
##############################################################################
my ($get_em, $get_coll);

##############################################################################
# Constants
##############################################################################
use constant DEBUG => 0;
use constant HAS_MULTISITE => 1;
use constant GROUP_PACKAGE => 'Bric::Util::Grp::Dest';
use constant INSTANCE_GROUP_ID => 29;

##############################################################################
# Fields
##############################################################################
# Public Class Fields

##############################################################################
# Private Class Fields
my @COLS = qw(id name description site__id copyable publish preview active);
my @PROPS = qw(name description site_id _copy _publish _preview _active
               move_method);

my $SEL_COLS = 's.id, s.name, s.description, s.site__id, s.copyable, '.
               's.publish, s.preview, s.active, c.disp_name, c.pkg_name, '.
               'm.grp__id';
my @SEL_PROPS = ('id', @PROPS, qw(_mover_class grp_ids));

my %BOOL_MAP = ( active      => 's.active = ?',
                 can_copy    => 's.copyable = ?',
                 can_publish => 's.publish = ?',
                 can_preview => 's.preview = ?');

my @SCOL_ARGS = ('Bric::Util::Coll::Server', '_servers', { active => 1 });
my @ACOL_ARGS = ('Bric::Util::Coll::Action', '_actions', {});
my @OCOL_ARGS = ('Bric::Util::Coll::OutputChannel', '_ocs', {});

my @ORD = qw(name description site_id move_method copy publish preview active);
my $meths;

##############################################################################

##############################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({
                         # Public Fields
                         id           => Bric::FIELD_READ,
                         name         => Bric::FIELD_RDWR,
                         description  => Bric::FIELD_RDWR,
                         site_id      => Bric::FIELD_RDWR,
                         move_method  => Bric::FIELD_RDWR,
                         grp_ids      => Bric::FIELD_READ,

                         # Private Fields
                         _mover_class => Bric::FIELD_NONE,
                         _copy        => Bric::FIELD_NONE,
                         _active      => Bric::FIELD_NONE,
                         _servers     => Bric::FIELD_NONE,
                         _actions     => Bric::FIELD_NONE,
                         _publish     => Bric::FIELD_NONE,
                         _preview     => Bric::FIELD_NONE
                        });
}

##############################################################################
# Class Methods
##############################################################################

=head1 Interface

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

site_id

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
    push @{$init->{grp_ids}}, INSTANCE_GROUP_ID;
    $self->SUPER::new($init);
}

##############################################################################

=item my $st = Bric::Dist::ServerType->lookup({ id => $id })

=item my $st = Bric::Dist::ServerType->lookup({ name => $name, site_id => $site_id })

Looks up and instantiates a new Bric::Dist::ServerType object based on the
Bric::Dist::ServerType object ID or name and site ID passed. If C<$id> or
C<$name> and C<$site_id> is not found in the database, C<lookup()> returns
C<undef>.

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
    my $pkg = shift;
    my $st = $pkg->cache_lookup(@_);
    return $st if $st;

    $st = $get_em->($pkg, @_);
    # We want @$st to have only one value.
    throw_dp(error => 'Too many ' . __PACKAGE__ . ' objects found.')
      if @$st > 1;
    return @$st ? $st->[0] : undef;
}

##############################################################################

=item my (@sts || $sts_aref) = Bric::Dist::ServerType->list($params)

Returns a list or anonymous array of Bric::Dist::ServerType objects based on the
search parameters passed via an anonymous hash. The supported lookup keys are:

=over 4

=item id

Destination ID. May use C<ANY> for a list of possible values.

=item move_method

Destination move method. May use C<ANY> for a list of possible values.

=item name

Destination name. May use C<ANY> for a list of possible values.

=item description

Destination description. May use C<ANY> for a list of possible values.

=item site_id

ID of Bric::Biz::Site object with which destinations may be associated. May
use C<ANY> for a list of possible values.

=item job_id

ID of Bric::Util::Job object with which destinations may be associated. May
use C<ANY> for a list of possible values.

=item resource_id

ID of Bric::Dist::Resource object with which destinations may be associated
via jobs. May use C<ANY> for a list of possible values.

=item output_channel_id

ID of Bric::Biz::OutputChannel object with which destinations may be
associated. May use C<ANY> for a list of possible values.

=item can_copy

Boolean value indicating whether resources should be copied to a temporary
location before distribution actions should be carried out on them. May use
C<ANY> for a list of possible values.

=item can_publish

Boolean value indicating whether or not the destination is distributed to upon
publish events.

=item can_preview

Boolean value indicating whether or not the destination is distributed to upon
preview events.

=item grp_id

ID of Bric::Util::Grp object with which destinations may be associated. May
use C<ANY> for a list of possible values.

=item active

Boolean value indicating whether the destination object is active.

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

##############################################################################

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

##############################################################################

=back

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

##############################################################################

=head2 Public Class Methods

=over 4

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

##############################################################################

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
    my $and_sftp = ENABLE_SFTP_MOVER ? '' : q{AND key_name <> 'sftp'};
    my $and_dav = ENABLE_WEBDAV_MOVER ? '' : q{AND key_name <> 'webdav'};
    my $sel = prepare_ca(qq{
        SELECT disp_name
        FROM   class
        WHERE  distributor = '1' $and_sftp $and_dav
        ORDER BY disp_name
    }, undef);
    return wantarray ? @{ col_aref($sel) } : col_aref($sel);
}

##############################################################################

=item $meths = Bric::Dist::ServerType->my_meths

=item (@meths || $meths_aref) = Bric::Dist::ServerType->my_meths(TRUE)

=item my (@meths || $meths_aref) = Bric::Dist::ServerType->my_meths(0, TRUE)

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

    unless ($meths) {
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

              site_id     => {
                              name     => 'site_id',
                              get_meth => sub { shift->get_site_id(@_) },
                              get_args => [],
                              set_meth => sub { shift->set_site_id(@_) },
                              set_args => [],
                              disp     => 'Site',
                              len      => 256,
                              req      => 0,
                              type     => 'short',
                              props    => {}
                             },

              site        => {
                              name     => 'site',
                              get_meth => sub { my $s = Bric::Biz::Site->lookup
                                                  ({ id => shift->get_site_id })
                                                  or return;
                                                $s->get_name;
                                            },
                              disp     => 'Site',
                              type     => 'short',
                              req      => 0,
                              props    => { type       => 'text',
                                            length     => 10,
                                            maxlength  => 10
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
    }

    if ($ord) {
        return wantarray ? @{$meths}{@ORD} : [@{$meths}{@ORD}];
    } elsif ($ident) {
        return wantarray ? $meths->{name} : [$meths->{name}];
    } else {
        return $meths;
    }
}

##############################################################################

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

Sets the server type description, first converting any non-Unix line endings.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_description {
    my ($self, $val) = @_;
    $val =~ s/\r\n?/\n/g if defined $val;
    $self->_set( [ 'description' ] => [ $val ]);
}

=item my $description = $st->get_site_id

Returns the site ID with which this ServerType is associated.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $st->set_site_id($site_id)

Associate this ServerType with a site.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

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

=item my (@ocs || $ocs_aref) = $st->get_output_channels

=item my (@ocs || $ocs_aref) = $st->get_output_channels(@oc_ids)

Returns a list or anonymous array of the Bric::Biz::OutputChannel objects
that represent the directories and/or files on which this server type acts.

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

sub get_output_channels {
    my $col = &$get_coll(shift, @OCOL_ARGS);
    $col->get_objs(@_);
}

##############################################################################

=item $st = $st->add_output_channels(@ocs)

Adds Output Channels to this server type. Call save() to save the
relationship.

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
    my $col = &$get_coll($self, @OCOL_ARGS);
    $col->add_new_objs(@_);
    $self->_set__dirty(1);
}

##############################################################################

=item $self = $st->del_output_channels(@ocs)

Dissociates Output Channels, represented as Bric::Biz::OutputChannel
objects, from the server type. call save() to save the dissociations to the
database.

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
    my $col = &$get_coll($self, @OCOL_ARGS);
    $col->del_objs(@_);
    $self->_set__dirty(1);
}

##############################################################################

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

=back

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::Coll::Server internally.

=cut

sub get_servers {
    my $col = &$get_coll(shift, @SCOL_ARGS);
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

=back

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::Coll::Server internally.

=cut

sub new_server {
    my ($self, $init) = @_;
    $init->{server_type_id} = $self->_get('id');
    my $col = &$get_coll($self, @SCOL_ARGS);
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

=back

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::Coll::Server internally.

=cut

sub del_servers {
    my $col = &$get_coll(shift, @SCOL_ARGS);
    $col->del_objs(@_);
}

##############################################################################

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

=back

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::Coll::Action internally.

=cut

sub get_actions {
    my $col = &$get_coll(shift, @ACOL_ARGS);
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

=back

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::Coll::Action internally.

=cut

sub new_action {
    my ($self, $init) = @_;
    $init->{server_type_id} = $self->_get('id');
    my $col = &$get_coll($self, @ACOL_ARGS);
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

=back

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::Coll::Action internally.

=cut

sub del_actions {
    my $col = &$get_coll(shift, @ACOL_ARGS);
    $col->del_objs(@_);
}

##############################################################################

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

##############################################################################

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

##############################################################################

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

##############################################################################

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

sub activate { $_[0]->_set(['_active'] => [1]) }

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

sub deactivate { $_[0]->_set(['_active'] => [0]) }

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

sub is_active { $_[0]->_get('_active') ? $_[0] : undef }

##############################################################################

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
            SET    @COLS = ?,
                   class__id = (SELECT id FROM class WHERE LOWER(disp_name) = LOWER(?))
            WHERE  id = ?
        }, undef);
        execute($upd, $self->_get('id', @PROPS), $id);
    } elsif ($dirt) {
        # It's a new resource. Insert it.
        local $" = ', ';
        my $fields = join ', ', next_key('server_type'), ('?') x $#COLS;
        my $ins = prepare_c(qq{
            INSERT INTO server_type (@COLS, class__id)
            VALUES ($fields, (SELECT id FROM class WHERE LOWER(disp_name) = LOWER(?)))
        }, undef);
        # Don't try to set ID - it will fail!
        execute($ins, $self->_get(@PROPS));
        # Now grab the ID.
        $id = last_key('server_type');
        $self->_set(['id'], [$id]);

        # And finally, register this person in the "All Destinations" group.
        $self->register_instance(INSTANCE_GROUP_ID, GROUP_PACKAGE);
    }

    # Okay, now save any changes to associated servers and actions.
    $servers->save($id) if $servers;
    $actions->save($id) if $actions;
    $ocs->save(server_type => $id) if $ocs;
    $self->SUPER::save;
    return $self;
}

##############################################################################

=back

=head1 Private

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

=over 4

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

=back

=head2 Private Functions

=over 4

=item my $st_aref = &$get_em( $pkg, $params )

=item my $st_ids_aref = &$get_em( $pkg, $params, 1 )

Function used by C<lookup()> and C<list()> to return a list of
Bric::Dist::ServerType objects or, if called with an optional third argument,
returns a list of Bric::Dist::ServerType object IDs (used by C<list_ids()>).

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
    my $tables = 'server_type s, class c, member m, dest_member sm';
    my $wheres = 's.class__id = c.id AND s.id = sm.object_id AND ' .
      "sm.member__id = m.id AND m.active = '1'";
    my @params;
    while (my ($k, $v) = each %$params) {
        if ($k eq 'id') {
            # Simple ID lookup.
            $wheres .= ' AND ' . any_where $v, 's.id = ?', \@params;
        } elsif ($BOOL_MAP{$k}) {
            # Simple boolean comparison.
            $wheres .= " AND $BOOL_MAP{$k}";
            push @params, $v ? 1 : 0;
        } elsif ($k eq 'move_method') {
            # We use the class display name for the move method.
            $wheres .= ' AND '
                    .  any_where $v, 'LOWER(c.disp_name) LIKE LOWER(?)', \@params;
        } elsif ($k eq 'job_id') {
            # Add job__server_type to the lists of tables and join to it.
            $tables .= ', job__server_type js';
            $wheres .= ' AND s.id = js.server_type__id AND '
                    .  any_where $v, 'js.job__id = ?', \@params;
        } elsif ($k eq 'output_channel_id') {
            # Add server_type__output_channel to the lists of tables and join
            # to it.
            $tables .= ', server_type__output_channel so';
            $wheres .= ' AND s.id = so.server_type__id AND '
                    .  any_where $v, 'so.output_channel__id = ?', \@params;
        } elsif ($k eq 'resource_id') {
            # Add job__server_type and job__resource to the lists of tables
            # and join to it.
            $tables .= ', job__server_type jst, job__resource jr';
            $wheres .= ' AND s.id = jst.server_type__id AND jst.job__id = jr.job__id AND '
                    .  any_where $v, 'jr.resource__id = ?', \@params;
        } elsif ($k eq 'grp_id') {
            # Add in the group tables a second time and join to them.
            $tables .= ", member m2, dest_member sm2";
            $wheres .= " AND s.id = sm2.object_id AND sm2.member__id = m2.id"
                    .  " AND m2.active = '1' "
                    .  any_where $v, 'AND m2.grp__id = ?', \@params;
        } elsif ($k eq 'site_id') {
            $wheres .= ' AND ' . any_where $v, 's.site__id = ?', \@params;
        } else {
            # It's just a string comparison.
            $wheres .= ' AND '
                    .  any_where $v, "LOWER(s.$k) LIKE LOWER(?)", \@params;
        }
    }

    # Assemble and prepare the query.
    my ($qry_cols, $order) = $ids ? (\'DISTINCT s.id', 's.id') :
      (\$SEL_COLS, 's.name, s.id');
    my $sel = prepare_c(qq{
        SELECT $$qry_cols
        FROM   $tables
        WHERE  $wheres
        ORDER BY $order
    }, undef);

    # Just return the IDs, if they're what's wanted.
    return col_aref($sel, @params) if $ids;

    # Grab all the records.
    execute($sel, @params);
    my (@d, @sts, %sts, $grp_ids);
    bind_columns($sel, \@d[0..$#SEL_PROPS]);
    my $last = -1;
    $pkg = ref $pkg || $pkg;
    while (fetch($sel)) {
        if ($d[0] != $last) {
            $last = $d[0];
            # Create a new server type object.
            my $self = bless {}, $pkg;
            $self->SUPER::new;
            # Get a reference to the array of group IDs.
            $grp_ids = $d[$#d] = [$d[$#d]];
            $self->_set(\@SEL_PROPS, \@d);
            $self->_set__dirty; # Disables dirty flag.
            $href ? $sts{$d[0]} = $self->cache_me :
              push @sts, $self->cache_me;
        } else {
            push @$grp_ids, $d[$#d];
        }
    }
    # Return the objects.
    return $href ? \%sts : \@sts;
};

=item my $rules = &$get_coll($self, $class, $key)

Returns the collection of objects stored under $key in $self. The collection is
a subclass Bric::Util::Coll object, identified by $class. See Bric::Util::Coll for
interface details.

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
    my ($self, $class, $key, $params) = @_;
    my $dirt = $self->_get__dirty;
    my ($id, $coll) = $self->_get('id', $key);
    $self->_set__dirty($dirt); # Reset the dirty flag.
    return $coll if $coll;
    $params->{server_type_id} = $id;
    $coll = $class->new(defined $id ? $params : undef);
    $self->_set([$key], [$coll]);
    $self->_set__dirty; # Unset the dirty flag.
    return $coll;
};

1;
__END__

=back

=head1 Notes

NONE.

=head1 Author

David Wheeler <david@justatheory.com>

=head1 See Also

L<Bric|Bric>

=cut
