package Bric::Dist::Action;

=head1 Name

Bric::Dist::Action - Interface to actions that can be performed on resources
for given server types.

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::Dist::Action;

  # Constructors.
  # Create a new object.
  my $action = Bric::Dist::Action->new;
  # Look up an existing object. May return a subclass of Bric::Dist::Action.
  $action = Bric::Dist::Action->lookup({ id => 1 });
  # Get a list of action objects.
  my @servers = Bric::Dist::Action->list({ type => 'Akamaize' });

  # Class methods.
  # Get a list of object IDs.
  my @st_ids = Bric::Dist::Action->list_ids({ type => 'Akamaize' });
  # Get an introspection hashref.
  my $int = Bric::Dist::Action->my_meths;
  my $bool = Bric::Dist::Action->has_more;

  # Instance Methods.
  my $id = $action->get_id;
  my $type = $action->get_type;
  # Changing the type will likely change the $action to a different subclass,
  # and will delete any attributes associated with the previous type.
  $action = $action->set_type($type);

  # Description is only available for types that have been looked up in the
  # database.
  my $description = $action->get_description;

  # The server type designation may be changed at will.
  my $st_id = $action->get_server_type_id;
  my $action = $action->set_server_type_id($st_id);

  # The list of MEDIA types can only be fetched on existing actions. The list
  # of MEDIA types is dependent on the type of action.
  my @medias = $action->get_media_types;
  my $medias = $action->get_media_href;

  # Perform the action.
  $action->do_it($job, $server_type);

  # Delete the action.
  $action->del

  # Save the action.
  $action->save;

=head1 Description

This class manages the actions that are applied for a given server type to the
files associated with a given job. The idea is that for any given server type,
an ordered list of actions will be performed whenever a job is executed for that
server type. For example, if there is a server type "Production Server", the
list of actions (represented as Bric::Dist::Action objects) for that server type
might be "Akamaize", "Ultraseek", "Gzip", and "Put". When a job (represented by
a Bric::Util::Job object) is executed for that server group, then each of those
actions will be instantiated in turn, and their do_it() methods called on the
job's resources.

The types of actions available to customers are created at development time, and
are represented both in the database and by subclasses of Bric::Dist::Action. They
can be changed and reordered for a given server type via the
Bric::Dist::ServerType interface. So Bric::Dist::Action will frequently not be
accessed directly, but via Bric::Dist::ServerType accessors.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Util::DBI qw(:all);
use Bric::Util::Fault qw(throw_dp throw_mni throw_gen rethrow_exception);
use Bric::Dist::Resource;
use Bric::Util::Attribute::Action;

################################################################################
# Inheritance
################################################################################
use base qw(Bric);

################################################################################
# Function and Closure Prototypes
################################################################################
my ($get_em, $make_obj, $reorder);

################################################################################
# Constants
################################################################################
use constant DEBUG => 0;

################################################################################
# Fields
################################################################################
# Public Class Fields
my @cols = qw(a.id a.ord a.server_type__id a.active t.name t.description m.name);
my @props = qw(id ord server_type_id _active type description medias_href);

my %nmap = (
    id             => 'a.id = ?',
    server_type_id => 'a.server_type__id = ?',
    action_type_id => 't.id = ?',
);
my %tmap = (
    type        => 'LOWER(t.name) LIKE LOWER(?)',
    action_type => 'LOWER(t.name) LIKE LOWER(?)',
    description => 'LOWER(t.description) LIKE LOWER(?)'
);

my @ord = qw(type ord description active);
my $meths;

################################################################################
# Private Class Fields
# Load the names of the various action classes.
my ($acts, $types);

################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({
                        # Public Fields
                         id => Bric::FIELD_READ,
                         ord => Bric::FIELD_READ,
                         server_type_id => Bric::FIELD_RDWR,
                         type => Bric::FIELD_RDWR,
                         description => Bric::FIELD_READ,
                         medias_href => Bric::FIELD_READ,

                         # Private Fields
                         _attr => Bric::FIELD_NONE,
                         _del => Bric::FIELD_NONE,
                         _old_ord => Bric::FIELD_NONE,
                         _active => Bric::FIELD_NONE
                        });
}

################################################################################
# Class Methods
################################################################################

=head1 Interface

=head2 Constructors

=over 4

=item my $act = Bric::Dist::Action->new($init)

Instantiates a Bric::Dist::Action object. An anonymous hash of initial values may
be passed. The supported initial value keys are:

=over 4

=item *

type

=item *

server_type_id

=back

The active property will be set to true by default. Call $act->save() to save
the new object.

B<Throws:>

=over 4

=item *

Unable to load action subclass.

=item *

Invalid parameter passed to constructor method.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub new {
    my ($pkg, $init) = @_;
    $init->{_active} = 1;
    my $self = $pkg->SUPER::new($init);
    $self->set_type($init->{type}) if $init->{type};
    return $self;
}

################################################################################

=item my $act = Bric::Dist::Action->lookup({ id => $id })

Looks up and instantiates a new Bric::Dist::Action object based on the
Bric::Dist::Action object ID passed. If $id is not found in the database, lookup()
returns undef.

B<Throws:>

=over

=item *

Invalid parameter passed to constructor method.

=item *

Too many Bric::Dist::Action objects found.

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

B<Side Effects:> If $id is found, populates the new Bric::Dist::Action object with
data from the database before returning it.

B<Notes:> NONE.

=cut

sub lookup {
    my $pkg = shift;
    my $act = $pkg->cache_lookup(@_);
    return $act if $act;

    $act = $get_em->($pkg, @_);
    # We want @$act to have only one value.
    throw_dp(error => 'Too many Bric::Dist::Action objects found.')
      if @$act > 1;
    return @$act ? $act->[0] : undef;
}

################################################################################

=item my (@acts || $acts_aref) = Bric::Dist::Action->list($params)

Returns a list or anonymous array of Bric::Dist::Action objects based on the
search parameters passed via an anonymous hash. The supported lookup keys are:

=over 4

=item id

Action ID. May use C<ANY> for a list of possible values.

=item action_type_id

The ID of an action type. May use C<ANY> for a list of possible values.

=item action_type

=item type

The name of an action type. May use C<ANY> for a list of possible values.

=item server_type_id

The ID of a destination (server type) with which actions may be associated.
May use C<ANY> for a list of possible values.

=item description

An action type description. May use C<ANY> for a list of possible values.

=back

B<Throws:>

=over 4

=item *

Invalid parameter passed to constructor method.

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

B<Side Effects:> Populates each Bric::Dist::Action object with data from the
database before returning them all.

B<Notes:> NONE.

=cut

sub list { wantarray ? @{ &$get_em(@_) } : &$get_em(@_) }

################################################################################

=item my $actions_href = Bric::Dist::Action->href($params)

Returns an anonymous hash of Bric::Dist::Action objects, where the keys are the
object IDs and the values are the objects themselves, based on the search
parameters passed via an anonymous hash. The supported lookup keys are the same
as for list().

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

B<Side Effects:> Populates each Bric::Dist::Action object with data from the
database before returning them all.

B<Notes:> NONE.

=cut

sub href { &$get_em(@_, 0, 1) }

################################################################################

=back

=head2 Destructors

=over 4

=item $act->DESTROY

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

=item my $ord = Bric::Dist::Action->next_ord($server_type_id)

Returns the next ordinal number in the sequence of actions for a given
server_type_id.

B<Throws:>

=over 4

=item *

Unable to load action subclass.

=item *

Invalid parameter passed to constructor method.

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

sub next_ord {
    my ($pkg, $st_id, $from, $to) = @_;
    my @ord = $pkg->list_ids({ server_type_id => $st_id });
    return @ord + 1;
}

=item my (@act_ids || $act_ids_aref) = Bric::Dist::Action->list_ids($params)

Returns a list or anonymous array of Bric::Dist::Action object IDs based on the
search criteria passed via an anonymous hash. The supported lookup keys are the
same as those for list().

B<Throws:>

=over 4

=item *

Invalid parameter passed to constructor method.

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

=item my (@types || $types_aref) = Bric::Dist::Action->list_types

Returns a list or anonymous array of the types of the supported actions.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub list_types { return wantarray ? @$types : $types }

################################################################################

=item my $bool = Bric::Dist::Action->has_more()

Returns true if the action has more properties than does the base class
(Bric::Dist::Action), and false if not. Here in Bric::Dist::Action it returns false,
so it only needs to be overridden to return true in subclasses of
Bric::Dist::Action that contain extra properties (such as
Bric::Dist::Action::Akamaize).

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub has_more { return }

################################################################################

=item $meths = Bric::Dist::Action->my_meths

=item (@meths || $meths_aref) = Bric::Dist::Action->my_meths(TRUE)

=item my (@meths || $meths_aref) = Bric::Dist::Action->my_meths(0, TRUE)

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

An anonymous hash of key/value pairs representing the values and display names
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
    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}]
      if $meths;

    # We don't got 'em. So get 'em!
    $meths = {
              type   => {
                              name     => 'type',
                              get_meth => sub { shift->get_type(@_) },
                              get_args => [],
                              set_meth => sub { shift->set_type(@_) },
                              set_args => [],
                              disp     => 'Type',
                              len      => 128,
                              req      => 1,
                              type     => 'short',
                              props    => {   type => 'select',
                                              vals => $types
                                          }
                             },
              ord   => {
                              name     => 'ord',
                              get_meth => sub { shift->get_ord(@_) },
                              get_args => [],
                              set_meth => sub { shift->set_ord(@_) },
                              set_args => [],
                              search   => 1,
                              disp     => 'Order',
                              len      => 3,
                              req      => 1,
                              type     => 'short',
                              props    => {   type => 'select',
                                              vals => [1..20]
                                          }
                             },
              description => {
                              name     => 'description',
                              get_meth => sub { shift->get_description(@_) },
                              get_args => [],
                              disp     => 'Description',
                              len      => 256,
                              req      => 0,
                              type     => 'short',
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

=item my $id = $act->get_id

Returns the ID of the Bric::Dist::Action object.

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

B<Notes:> If the Bric::Dist::Action object has been instantiated via the new()
constructor and has not yet been C<save>d, the object will not yet have an ID,
so this method call will return undef.

=item my $type = $act->get_type

=item my $type = $act->get_name

Returns the type of the action, e.g., "FTP" or "Akamaize."

B<Throws:>

=over 4

=item *

Cannot load action class.

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'type' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

*get_name = sub { shift->get_type };

=item $self = $act->set_type($type)

Sets the type of the action. The type must be the type of a supported action.
Call Bric::Dist::Action->list_types() to get a list of supported actions.

B<Throws:>

=over 4

=item *

Unable to load action subclass.

=item *

Problems retrieving fields.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

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

sub set_type {
    my ($self, $type) = @_;

    # Clear out the attributes for the last type.
    $self->_clear_attr;

    # Get the new type class.
    my $class = $acts->{$type};

    # Rebless $self with the new class type and set the type.
    $self = $class->_rebless($self);
    $self->_set(['type'], [$type]);
}

=item my $order = $act->get_ord

Returns the number representing this action's place in the order of execution
for all the actions associated with the server_type_id with which this action is
associated.

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

B<Notes:> NONE.

=item $self = $act->set_ord($order)

Sets the order of the action. This number represents where in the sequence of
actions associated with the server_type_id with which this action is associated
that this action will be executed. If this property is never set on a new
action, then the order will default to the last in the sequence of actions. If
it is set, and it comes before other, pre-existing actions, those actions will
be shifted down in the list of actions.

B<Throws:>

=over 4

=item *

Problems retrieving fields.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_ord {
    my ($self, $new) = @_;
    $self->_set([qw(ord _old_ord)], [$new, $self->_get('ord')]);
}

=item my $description = $act->get_description

Returns the description of the action.

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

=item my $server_type_id = $act->get_server_type_id

Returns the ID of the Bric::Dist::ServerType object for which this action will be
performed.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'server_type_id' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $act->set_server_type_id($server_type_id)

Associates this action with a Bric::Dist::ServerType object so that this action
can be performed for servers of that type.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'server_type_id' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my (@medias || $medias_aref) = $action->get_media_types

Returns a list or anonymous array of the MEDIA types that apply to this
action. Returns an empty list (or undef in a scalar context) if this action
applies to  B<all> MEDIA types.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_media_types {
    my $medias = $_[0]->_get('medias_href');
    return if $medias->{none};
    return wantarray ? sort keys %$medias : [ sort keys %$medias ];
}

################################################################################

=item my (@medias || $medias_aref) = $action->get_media_href

Returns an anonymous hash of the MEDIA types that apply to this action. Returns
undef if this action applies to B<all> MEDIA types.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_media_href {
    my $medias = $_[0]->_get('medias_href');
    return $medias->{none} ? undef : $medias;
}

################################################################################

=item $action = $action->del

Marks the Bric::Dist::Action object to be deleted from the database. Call
$action->save to actually finish it off.

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

sub del { $_[0]->_set(['_del'], [1]) }

################################################################################

=item $self = $action->activate

Activates the Bric::Dist::Action object. Call $action->save to make the change
persistent. Bric::Dist::Action objects instantiated by new() are active by
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

=item $self = $action->deactivate

Deactivates (deletes) the Bric::Dist::Action object. Call $action->save to make
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

=item $self = $action->is_active

Returns $self if the Bric::Dist::Action object is active, and undef if it is not.

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

=item $self = $act->save

Saves any changes to the Bric::Dist::Action object. Returns $self on success and
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
    return $self unless $self->_get__dirty;
    my ($id, $attr, $del, $ord, $old_ord, $st_id) =
      $self->_get(qw(id _attr _del ord _old_ord server_type_id));

    if (defined $id && $del) {
        # It has been marked for deletion. So do it!
        my $del = prepare_c(qq{
            DELETE FROM action
            WHERE  id = ?
        }, undef);
        execute($del, $id);
        &$reorder($st_id);
    } elsif (defined $id) {
        # It's an existing record. Update it.
        my $upd = prepare_c(qq{
            UPDATE action
            SET    server_type__id = ?,
                   active = ?,
                   action_type__id = (SELECT id FROM action_type WHERE name = ?)
            WHERE  id = ?
        }, undef);
        execute($upd, $self->_get(qw(server_type_id _active type)), $id);
        # Reorder the actions, if this one has changed.
        &$reorder($st_id, $old_ord, $ord) if $old_ord && $old_ord != $ord;
    } else {
        # It's a new resource. Insert it. Start by setting the order, if
        # necessary.
        my $next_ord = next_ord($self, $st_id);
        my $next = next_key('action');
        my $ins = prepare_c(qq{
            INSERT INTO action (id, ord, server_type__id, active, action_type__id)
            VALUES ($next, ?, ?, ?, (SELECT id FROM action_type WHERE name = ?))
        }, undef);

        # Don't try to set ID - it will fail!
        execute($ins, $next_ord, $self->_get(qw(server_type_id _active type)));
        # Now grab the ID.
        $id = last_key('action');
        $self->_set(['id'], [$id]);
        # Finally, reorder the actions, if necessary.
        $ord && $ord != $next_ord ? &$reorder($st_id, $next_ord, $ord)
          : $self->_set(['ord'], [$next_ord]);
        $attr->set_object_id($id) if $attr;
    }

    # Okay, now save any changes to its attributes.
    $attr->save if $attr;
    $self->SUPER::save;
}

################################################################################

=item $self = $act->do_it($job)

Performs the action on the resources associated with $job. Must be overridden
in Bric::Dist::Action subclasses.

B<Throws:>

=over 4

=item *

Method not implemented.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub do_it {
    # Look up the type. If it's "Put" or "Delete", then call the put() or del()
    # functions in the Mover class associated with the ServerType.
    throw_mni(error => __PACKAGE__ . '::do_it method not implemented.');
}

################################################################################

=item $self = $act->undo_it($job)

Undoes the action on the resources associated with $job. Here is is actually a
no-op that returns false, but when overridden, it should return true, as
Bric::Util::Job uses this return value to determine whether or not to log an
event.

B<Throws:>

=over 4

=item *

Method not implemented.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub undo_it { shift }

################################################################################

=back

=head1 Private

=head2 Private Class Methods

=over 4

=item __PACKAGE__->_register_action($key)

Protected method called by action subclasses at startup time so they can
register themselves as available actions. Some may wish to not register
themselves under certain circumstances. For example,
Bric::Dist::Action::DTDValidate should only be registered if XML::LibXML has
been installed. Thus that class only registers itself if XML::LibXML does not
load.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _register_action {
    my ($class, $key) = @_;
    $acts->{$key} = $class;
    push @$types, $key;
}

=back

=head2 Private Instance Methods

=over 4

=item my $attr = $action->_get_attr

Used by subclasses to access an action's Bric::Util::Attribute::Action object.

B<Throws:>

=over 4

=item *

Problems retrieving fields.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _get_attr {
    my ($self, $subsys) = @_;
    my ($id, $attr) = $self->_get('id', '_attr');
    return $attr if $attr;
    $attr = Bric::Util::Attribute::Action->new({ object_id => $id,
                                                 subsys => $subsys });
    $self->_set(['_attr'], [$attr]);
    return $attr;
};

##############################################################################

=item $action = $action->_clear_attr

A No-op function that may be overridden in subclasses with attributes. It is
called by set_type() above so that subclasses of Bric::Dist::Action can clear
their attributes before the Bric::Dist::Action object is blessed into a different
class. See Bric::Dist::Action::Akamaize for an example.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _clear_attr { $_[0] }

##############################################################################

=item $action = $action->_rebless

Called by C<set_type()> to rebless an action into a new class. Useful for for
subclasses to override in order to set default values on attributes, such as
they would typically do in C<new()>.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _rebless { bless $_[1], ref $_[0] || $_[0] }

##############################################################################

=back

=head2 Private Functions

=over 4

=item my $act_aref = &$get_em( $pkg, $params )

=item my $act_ids_aref = &$get_em( $pkg, $params, 1 )

Function used by lookup() and list() to return a list of Bric::Dist::Action objects
or, if called with an optional third argument, returns a list of Bric::Dist::Action
object IDs (used by list_ids()).

B<Throws:>

=over 4

=item *

Unable to load action subclass.

=item *

Invalid parameter passed to constructor method.

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

$get_em = sub {
    my ($pkg, $params, $ids, $href) = @_;
    my (@wheres, @params);
    while (my ($k, $v) = each %$params) {
        if ($nmap{$k}) {
            push @wheres, any_where $v, $nmap{$k}, \@params;
        } elsif ($tmap{$k}) {
            push @wheres, any_where $v, $tmap{$k}, \@params;
        } elsif ($k eq 'active') {
            push @wheres, 'a.active = ?';
            push @params, $v ? 1 : 0;
        } else {
            throw_gen "Invalid parameter '$k' passed to constructor method.";
        }
    }

    # Assemble the WHERE clause.
    my $where = @wheres ? "\n               AND " . join ' AND ',
      @wheres : '';

    # Assemble and prepare the query.
    my $qry_cols = $ids ? ['DISTINCT a.id, a.server_type__id, a.ord']
      : \@cols;
    local $" = ', ';
    my $sel = prepare_ca(qq{
        SELECT @$qry_cols
        FROM   action a, action_type t, action_type__media_type am, media_type m
        WHERE  a.action_type__id = t.id
               AND t.id = am.action_type__id
               AND am.media_type__id = m.id $where
        ORDER BY a.server_type__id, a.ord
    }, undef);

    # Just return the IDs, if they're what's wanted.
    return col_aref($sel, @params) if $ids;

    # Grab all the records.
    execute($sel, @params);
    my (@d, @init, $media, @acts, %acts);
    my $last = -1;
    bind_columns($sel, \@d[0..$#cols - 1], \$media);
    $pkg = ref $pkg || $pkg;
    while (fetch($sel)) {
        if ($d[0] != $last) {
            # Create a new object.
            $href ? $acts{$init[0]} = &$make_obj($pkg, \@init)
              : push @acts, &$make_obj($pkg, \@init) unless $last == -1;
            # Get the new record.
            $last = $d[0];
            @init = (@d, {});
        }
        # Grab the MEDIA type.
        $init[$#init]->{$media} = 1;
    }
    # Grab the last object.
    $href ? $acts{$init[0]} = &$make_obj($pkg, \@init)
      : push @acts, &$make_obj($pkg, \@init) if @init;
    # Return the objects.
    return $href ? \%acts : \@acts;
};

################################################################################]

=item my $action = &$make_obj( $pkg, $init )

Instantiates a Bric::Dist::Action object. Used by &$get_em().

B<Throws:>

=over 4

=item *

Unable to load action subclass.

=item *

Invalid parameter passed to constructor method.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$make_obj = sub {
    my ($pkg, $init) = @_;
    if ($init->[4]) {
        $pkg = $acts->{$init->[4]} ||= "Bric::Dist::Action::$init->[4]";
        # XXX Is this eval safe? I think it is.
        eval "require $acts->{$init->[4]}";
        throw_gen(error => "Unable to load $acts->{$init->[4]} action subclass.",
                  payload => $@)
          if $@;
    }
    my $self = bless {}, $pkg;
    $self->SUPER::new;
    $self->_set(\@props, $init);
    $self->cache_me;
};

################################################################################

=item my $bool = &$reorder( $server_type_id, $from_ord, $to_ord )

Reorders the list of actions for a given server_type_id. Pass in the
server_type_id and the ordinal number to change from to the ordinal number to
change to. The action that was number $from_ord will be changed to number
$to_ord, and the order of the other actions will be shifted to accommodate it.
For example, if you had the following actions:

  Order  ID  Action
  -----  --  ------------------
      1  11  Clean HTML
      2  12  Akamaize
      3  13  Move
      4  14  Go Home

To change the order so that "Akamaize" precedes "Clean HTML", call this function
like so:

  &$reorder(12, 2, 1);

And the Data will be reordered in this manner:

  Order  ID  Action
  -----  --  ------------------
      1  12  Akamaize
      2  11  Clean HTML
      3  13  Move
      4  14  Go Home

B<Throws:>

=over 4

=item *

Unable to load action subclass.

=item *

Invalid parameter passed to constructor method.

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

$reorder = sub {
    my ($st_id, $from, $to) = @_;
    my @ord = list_ids(undef, { server_type_id => $st_id });
    if ($to) {
        $from ||= 1 + (reverse sort { $a <=> $b } @ord)[0];
        splice(@ord, $to-1, 0, splice(@ord, $from - 1, 1));
    }

    my $upd = prepare_c(qq{
        UPDATE action
        SET    ord = ?
        WHERE  id = ?
    }, undef);

    my $i = 0;
    begin();
    eval {
        foreach (@ord) { execute($upd, ++$i, $_) }
        commit();
    };

    # If there was an error, rollback and die. Otherwise, commit.
    rollback() && rethrow_exception(error => $@) if $@;
    return 1;
};

1;
__END__

=back

=head1 Adding a New Action

=over 4

=item *

Add a new subclass for Bric::Dist::Action. Use Bric::Dist::Action::Email
and Bric::Dist::Action::DTDValidate as models. Be sure to call
C<< __PACKAGE__->_register_action($key) >> to register your action subclass.

=item *

Add inserts to F<sql/Pg/Bric/Dist/ActionType.val>. Note that the name inserted
here must be exactly the same as the $key argument to your call
C<_register_action()>. If your action can act on files of any type, add one
record to the action_type__media_type table with the media_type__id column set
to 0, which corresponds to no (and therefore all) media types.

=item *

Add an upgrade script with the above inserts. Use
F<inst/upgrade/1.7.0/email_action.pl> as a model.

=item *

Add a test class to test your action. Subclass Bric::Dist::Action::DevTest.
Use Bric::Dist::Action::Email::DevTest as a model.

=item *

Run C<make devtest> to make sure that all tests pass.

=item *

Add a C<use> statement for your new action to Bric::App::Handler.

=item *

Follow the instructions in L<Bric::Hacker|Bric::Hacker> to create a patch and
send it to bricolage-devel@lists.sourceforge.net.

=back

=head1 Notes

NONE.

=head1 Author

David Wheeler <david@justatheory.com>

=head1 See Also

L<Bric|Bric>

=cut
