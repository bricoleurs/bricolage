package Bric::Biz::Contact;

=head1 Name

Bric::Biz::Contact - Interface to Contacts

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::Biz::Contact

  # Constructors.
  my $c = Bric::Biz::Contact->new($init);
  my $c = Bric::Biz::Contact->lookup({ id => $id });
  my @c = Bric::Biz::Contact->list($params);

  # Class Methods.
  my @cids = Bric::Biz::Contact->list_ids($params);
  my $methods = Bric::Biz::Contact->my_meths;

  # Contact Type managment.
  my @types = Bric::Biz::Contact->list_types;
  my $types_href = Bric::Biz::Contact->href_types;
  my @types = Bric::Biz::Contact->list_alertable_types;
  my $types_href = Bric::Biz::Contact->href_alertable_types;
  my $type_ids_href = Bric::Biz::Contact->href_alertable_type_ids;
  my $bool = Bric::Biz::Contact->edit_type($type, $description);
  my $bool = Bric::Biz::Contact->deactivate_type($type);

  # Instance Methods.
  my $id = $c->get_id;
  my $type = $c->get_type;
  $c = $c->set_type($type);
  my $desc = $c->get_description;
  my $value = $c->get_value;
  $c = $c->set_value($value);

  $c = $c->activate;
  $c = $c->deactivate;
  $c = $c->is_active;

  $c = $c->save;

=head1 Description

This class manages contacts. Currently, contacts are only associated with
Bric::Biz::Person objects, but they could conceivably be associated with other
objects, e.g., Bric::Biz::Org.

A contact is a method (other than snail mail) to contact a person. Default
contact types include "Primary Email," "Secondary Email," "Office Phone,"
"Mobile Phone," "AOL Instant Messenger," etc. These types can be modified and new
contact types can be added via this class' class methods. Each individual
Bric::Biz::Contact object has an associated type, the type's description, and
a value. Each is also associated with another object, so they will often be
accessed from that object (see Bric::Biz::Person for an example).

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Util::DBI qw(:all);
use Bric::Util::Fault qw(throw_dp);

################################################################################
# Inheritance
################################################################################
use base qw(Bric);

################################################################################
# Function and Closure Prototypes
################################################################################
my ($get_em, $get_types);

################################################################################
# Constants
################################################################################
use constant DEBUG => 0;

################################################################################
# Fields
################################################################################
# Public Class Fields
my @val_cols = qw(id value active);
my @val_props = qw(id value _active);
my @type_cols = qw(c.type c.description);
my @type_props = qw(type description);
my @cols = (qw(v.id v.value v.active), @type_cols);
my @props = (@val_props, @type_props);
my $meths;
my @ord = qw(type description value);

################################################################################
# Private Class Fields
# Identifies databse columns and object keys.

################################################################################

################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({
                         # Public Fields
                         id =>  Bric::FIELD_READ,
                         type => Bric::FIELD_RDWR,
                         description => Bric::FIELD_READ,
                         alertable => Bric::FIELD_READ,
                         value => Bric::FIELD_RDWR,

                         # Private Fields
                         _active => Bric::FIELD_NONE,
                         _retyped => Bric::FIELD_NONE
                        });
}

################################################################################
# Class Methods
################################################################################

=head1 Interface

=head2 Constructors

=over 4

=item my $c = Bric::Biz::Contact->new()

=item my $c = Bric::Biz::Contact->new($init)

Instantiates a Bric::Biz::Contact object. An anonymous hash of initial values may be
passed. The supported initial value keys are:

=over 4

=item *

type

=item *

value

=back

The active property will be set to true by default. Call $c->save() to save the
new object.

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

sub new {
    my ($pkg, $init) = @_;
    my $self = bless {}, ref $pkg || $pkg;
    $init->{_active} = 1;
    $self->SUPER::new($init);
}

################################################################################

=item my $c = Bric::Biz::Contact->lookup({ id => $id })

Looks up and instantiates a new Bric::Biz::Contact object based on the
Bric::Biz::Contact object ID passed. If $id is not found in the database, lookup()
returns undef.

B<Throws:>

=over

=item *

Too many Bric::Biz::Contact objects found.

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

B<Side Effects:> If $id is found, populates the new Bric::Biz::Contact object with
data from the database before returning it.

B<Notes:> NONE.

=cut

sub lookup {
    my $pkg = shift;
    my $contact = $pkg->cache_lookup(@_);
    return $contact if $contact;

    $contact = $get_em->($pkg, @_);
    # We want @$contact to have only one value.
    throw_dp(error => 'Too many Bric::Biz::Contact objects found.') if @$contact > 1;
    return @$contact ? $contact->[0] : undef;
}

################################################################################

=item my (@contacts || $contact_aref) = Bric::Biz::Contact->list($params)

Returns a list or anonymous array of Bric::Biz::Contact objects based on the search
parameters passed via an anonymous hash. The supported lookup keys are:

=over 4

=item id

Contact ID. May use C<ANY> for a list of possible values.

=item type

Contact type. May use C<ANY> for a list of possible values.

=item description

Contact description. May use C<ANY> for a list of possible values.

=item value

Contact value. May use C<ANY> for a list of possible values.

=item person_id

ID of person object associated with contacts. May use C<ANY> for a list of
possible values.

=item alertable

Boolean indicating whether or not alerts can be sent to contacts of this type.

=back

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

B<Side Effects:> Populates each Bric::Biz::Contact object with data from the
database before returning them all.

B<Notes:> NONE.

=cut

sub list {  wantarray ? @{ &$get_em(@_) } : &$get_em(@_) }

################################################################################

=item my $contacts_href = Bric::Biz::Contact->href($params)

Works the same as list(), with the same arguments, except it returns a hash or
hashref of Bric::Biz::Contact objects, where the keys are the contact IDs, and the
values are the contact objects.

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

B<Side Effects:> Populates each Bric::Biz::Contact object with data from the
database before returning them all.

B<Notes:> NONE.

=cut

sub href {  &$get_em(@_, 0, 1) }

=back

=head2 Destructors

=over 4

=item $p->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=back

=cut

sub DESTROY {}

################################################################################

=head2 Public Class Methods

=over 4

=item my (@c_ids || $c_ids_aref) = Bric::Biz::Contact->list_ids($params)

Returns a list or anonymous array of Bric::Biz::Contact object IDs based on the
search parameters passed via an anonymous hash. The supported lookup keys are
the same as those for list().

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

sub list_ids { wantarray ? @{ &$get_em(@_, 1) } : &$get_em(@_, 1) }

################################################################################

=item $meths = Bric::Biz::Conatact->my_meths

=item (@meths || $meths_aref) = Bric::Biz::Contact->my_meths(TRUE)

=item my (@meths || $meths_aref) = Bric::Biz:::Contact->my_meths(0, TRUE)

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
    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}]
      if $meths;

    # We don't got 'em. So get 'em!
    my $types = list_types();
    $meths = {
              type        => {
                              name     => 'type',
                              get_meth => sub { shift->get_type(@_) },
                              get_args => [],
                              set_meth => sub { shift->set_type(@_) },
                              set_args => [],
                              disp     => 'Type',
                              type     => 'short',
                              len      => 32,
                              req      => 0,
                              search   => 1,
                              props    => {   type => 'select',
                                              vals => $types
                                          }
                             },
              description => {
                              name     => 'description',
                              get_meth => sub { shift->get_description(@_) },
                              get_args => [],
                              set_meth => sub { shift->set_description(@_) },
                              set_args => [],
                              disp     => 'Description',
                              search   => 1,
                              len      => 64,
                              req      => 0,
                              type     => 'short',
                              props    => {   type => 'textarea',
                                              rows => 4,
                                              cols => 40
                                          }
                             },
              value      => {
                             name     => 'value',
                             get_meth => sub { shift->get_value(@_) },
                             get_args => [],
                             set_meth => sub { shift->set_value(@_) },
                             set_args => [],
                             disp     => 'Value',
                             search   => 1,
                             len      => 64,
                             req      => 0,
                             type     => 'short',
                             props    => {   type      => 'text',
                                             length    => 32,
                                             maxlength => 256
                                         }
                            }
             };
    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}];
}

################################################################################

=item my (@types || $type_aref) = Bric::Biz::Contact->list_types

Returns a list or anonymous array of all the possible types (names)
of contacts. Use these types to set the type of a contact via $c->set_type().

B<Throws:>

=over 4

=item *

Unable to prepare SQL statement.

=item *

Unable to connect to database.

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

sub list_types { &$get_types() }

################################################################################

=item my $type_href = Bric::Biz::Contact->href_types

Returns a hash list or anonymous hash of all the possible types of contacts. The
hash keys are the type names, and the hash values are the descriptions.

B<Throws:>

=over 4

=item *

Unable to prepare SQL statement.

=item *

Unable to connect to database.

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

sub href_types { &$get_types(1) }

################################################################################

=item my (@types || $type_aref) = Bric::Biz::Contact->list_alertable_types

Returns a list or anonymous array of contact types that are alertable, that is,
contacts of these types may be used for sending alerts.

B<Throws:>

=over 4

=item *

Unable to prepare SQL statement.

=item *

Unable to connect to database.

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

sub list_alertable_types { &$get_types(undef, 1) }

################################################################################

=item my $types_aref = Bric::Biz::Contact->href_alertable_types

Returns a hash list or anonymous hash of contact types that are alertable, that
is, contacts of these types may be used for sending alerts. The hash keys are
the type names and the values are their descriptions.

B<Throws:>

=over 4

=item *

Unable to prepare SQL statement.

=item *

Unable to connect to database.

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

sub href_alertable_types { &$get_types(1, 1) }

################################################################################

=item my $types_aref = Bric::Biz::Contact->href_alertable_type_ids

Returns a hash list or anonymous hash of contact types that are alertable, that
is, contacts of these types may be used for sending alerts. The hash keys are
they type names and the values are theiry IDs. Used by Bric::Util::Alert.

B<Throws:>

=over 4

=item *

Unable to prepare SQL statement.

=item *

Unable to connect to database.

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

sub href_alertable_type_ids { &$get_types(1, 1, 1) }

################################################################################

=item my $success = Bric::Biz::Contact->edit_type($type, $description)

Adds or alters a contact type. If the type exists, its description will be
updated and it will be activated. If it does not exist, it will be created.

B<Throws:>

=over 4

=item *

Unable to prepare SQL statement.

=item *

Unable to connect to database.

=item *

Unable to execute SQL statement.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub edit_type {
    my ($pkg, $type, $desc) = @_;
    my $upd = prepare_c(qq{
        UPDATE contact
        SET    description = ?,
               active = ?
        WHERE  type = ?
    }, undef);
    return 1 if execute($upd, $desc, 1, $type) > 0;

    my $ins = prepare_c(qq{
        INSERT INTO contact (id, type, description, active, alertable)
        VALUES (${\next_key('contact')}, ?, ?, ?, 0)
    }, undef);
    execute($ins, $type, $desc, 1);
}

################################################################################

=item my $success = Bric::Biz::Contact->deactivate_type($type)

Deletes a type. All contacts of this type will be automatically deactivated. To
reactivate a type, use edit_type(); all existing contacts of that type will then
be available again.

B<Throws:>

=over 4

=item *

Unable to prepare SQL statement.

=item *

Unable to connect to database.

=item *

Unable to execute SQL statement.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub deactivate_type {
    my ($pkg, $type) = @_;
    my $upd = prepare_c(qq{
        UPDATE contact
        SET    active = ?
        WHERE  type = ?
    }, undef);
    execute($upd, 0, $type);
    return 1;
}

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item my $id = $c->get_id

Returns the ID of the Bric::Biz::Contact object.

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

B<Notes:> If the Bric::Biz::Contact object has been instantiated via the new()
constructor and has not yet been C<save>d, the object will not yet have an ID,
so this method call will return undef.

=item my $type = $c->get_type

Returns the type of the Bric::Biz::Contact object.

B<Throws:>

=over 4

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

=item $self = $c->set_type($type)

Sets the type type of the contact. The type type must be a valid type as
returned by get_types().

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

sub set_type {
    my $self = shift;
    $self->_set([qw(_retyped description type)],
                [$self->_get('type'), undef, shift]);
}

=item my $description = $c->get_description

Returns the description of the Bric::Biz::Contact object. If the contact has not
been looked up from the database or if its type has changed, description
will be C<undef>.

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

=item $self = $c->set_description( $description )

Sets the description of the Bric::Biz::Contact object, first converting
non-Unix line endings.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_description {
    my ($self, $val) = @_;
    $val =~ s/\r\n?/\n/g if defined $val;
    $self->_set( [ 'description' ] => [ $val ]);
}

=item my $value =  $c->get_value

Returns the value of the Bric::Biz::Contact object.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'value' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $c->set_value($value)

Sets the value of the Bric::Biz::Contact object. Returns $self on success and undef
on failure.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'value' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $c->activate

Activates the Bric::Biz::Contact object. Call $p->save to make the change
persistent. Bric::Biz::Contact objects instantiated by new() are active by default.

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

=item $self = $c->deactivate

Deactivates (deletes) the Bric::Biz::Contact object. Call $p->save to make the
change persistent.

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

=item $self = $c->is_active

Returns $self if the Bric::Biz::Contact object is active, and undef if it is not.

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

=item $self = $p->save

Saves any changes to the Bric::Biz::Contact object, including changes to associated
contacts (Bric::Biz::Attribute::Contact::Contact objects) and attributes
(Bric::Biz::Attribute::Contact objects). Returns $self on success and undef on
failure.

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

B<Side Effects:> Cleans out internal cache of Bric::Biz::Attr::Contact::Contact and
Bric::Biz::Attribute::Contact objects to reflect what is in the database.

B<Notes:> NONE.

=cut

sub save {
    my $self = shift;
    return unless $self->_get__dirty;
    my ($id, $retyped) = $self->_get(qw(id _retyped));

    if ($id) {
        # It's an existing contact. Update it.
        if ($retyped) {
            # The type has been changed. Requires a more sophisticated update.
            my $upd = prepare_c(qq{
                UPDATE contact_value
                SET    value = ?, contact__id = (
                           SELECT id
                           FROM   contact
                           WHERE  type = ?
                       ), active = ?
                WHERE  id = ?
            }, undef);
            execute($upd, $self->_get(qw(value type _active)), $id);
            $self->_set(['_retyped'], [undef]);
        } else {
            local $" = ' = ?, '; # Simple way to create placeholders with an array.
            my $upd = prepare_c(qq{
                UPDATE contact_value
                SET    @val_cols = ?
                WHERE  id = ?
            }, undef);
            execute($upd, $self->_get(@val_props), $id);
        }
    } else {
        # It's a new contact. Insert it.
        local $" = ', ';
        my $ins = prepare_c(qq{
            INSERT INTO contact_value (id, value, active, contact__id)
            VALUES (${ \next_key('contact_value') }, ?, ?, (
                SELECT id
                FROM   contact
                WHERE  type = ?)
            )
        }, undef);
        # Don't try to set ID - it will fail!
        execute($ins, $self->_get(qw(value _active type)));
        # Now grab the ID.
        $self->_set({id => last_key('contact_value')});
    }
    $self->SUPER::save;
    return $self;
}

################################################################################

=back

=head1 Private

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

=over 4

=item my $contacts_aref = &$get_em( $pkg, $search_href )

=item my $contacts_ids_aref = &$get_em( $pkg, $search_href, 1 )

Function used by lookup() and list() to return a list of Bric::Biz::Contact objects
or, if called with an optional third argument, returns a listof Bric::Biz::Contact
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
    my $tables = "contact c, contact_value v";
    while (my ($k, $v) = each %$params) {
        if ($k eq 'id') {
            push @wheres, any_where($v, 'v.id = ?', \@params);
        } elsif ($k eq 'value') {
            push @wheres, any_where($v, "LOWER(v.$k) LIKE LOWER(?)", \@params);
        } elsif ($k eq 'person_id') {
            $tables .= ', person__contact_value pcv';
            push @wheres, 'v.id = pcv.contact_value__id',
              any_where($v, 'pcv.person__id = ?', \@params);
        } elsif ($k eq 'alertable') {
            push @wheres, any_where($v ? 1 : 0, "c.$k = ?", \@params);
        } else {
            push @wheres, any_where($v,"LOWER(c.$k) LIKE LOWER(?)", \@params);
        }
    }

    my $where = defined $params->{id} ? '' : " AND v.active = '1'";
    local $" = ' AND ';
    $where .= " AND @wheres" if @wheres;

    local $" = ', ';
    my @qry_cols = $ids ? ('v.id') : @cols;
    my $sel = prepare_ca(qq{
        SELECT @qry_cols
        FROM   $tables
        WHERE  c.id = v.contact__id
               $where
        ORDER BY c.id
    }, undef);

    # Just return the IDs, if they're what's wanted.
    return col_aref($sel, @params) if $ids;

    execute($sel, @params);
    my (@d, @contacts, %contacts);
    bind_columns($sel, \@d[0..$#cols]);
    $pkg = ref $pkg || $pkg;
    while (fetch($sel)) {
        my $self = bless {}, $pkg;
        $self->SUPER::new;
        $self->_set(\@props, \@d);
        $self->_set__dirty; # Disables dirty flag.
        $href ? $contacts{$d[0]} = $self->cache_me :
          push @contacts, $self->cache_me;
    }
    return $href ? \%contacts : \@contacts;
};

################################################################################

=item my (@types || $types_aref) = &$get_types()

=item my (%types || $types_href) = &$get_types(1)

=item my (@alertable_types || $alertable_types_aref) = &$get_types(undef, 1)

=item my (%alertable_types || $alertable_types_href) = &$get_types(1, 1)

=item my (%alertable_type_ids || $alertable_type_ids_href) = &$get_types(1, 1, 1)

Function used by list_types(), href_types(), list_alertable_types(),
href_alertable_types(), and href_alertable_type_ids() to return an anonymous
array or anonymous hash of contact types.

The arguments are as follows:

=over

=item *

If no arguments are passed, a simple list of contact type names is returned.

=item *

The first argument requires that a hash list or anonymous hash be returned,
where the hash keys are the contact type names and the values are the contact
type descriptions.

=item *

The second argument specifies that the values returned by the the method reflect
only those contact types that are alertable.

=item *

The third argument specifies that the hash values returned by the inclusion of
the second argument be the contact type IDs, rather than their descriptions.

=back

B<Throws:>

=over 4

=item *

Unable to prepare SQL statement.

=item *

Unable to connect to database.

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

$get_types = sub {
    my ($href, $alert, $ids) = @_;
    my @qry_cols = $href ? ('c.id', @type_cols) : ('c.type');
    my $where = $alert ? "AND alertable = '1'" : '';

    local $" = ', ';
    my $sel = prepare_ca(qq{
        SELECT @qry_cols
        FROM   contact c
        WHERE  active = '1' $where
        ORDER BY c.id
    }, undef);

    # Just return a list of types unless an href is wanted.
    return wantarray ? @{ col_aref($sel) } : col_aref($sel) unless $href;

    # Create the href and then return it.
    execute($sel);
    my ($type, $desc, $id, %types);
    bind_columns($sel, \($id, $type, $desc));
    if ($ids) {
        while (fetch($sel)) { $types{$type} = $id }
    } else {
        while (fetch($sel)) { $types{$type} = $desc }
    }
    return wantarray ? %types : \%types;
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
