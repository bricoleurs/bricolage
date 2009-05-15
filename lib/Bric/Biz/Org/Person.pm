package Bric::Biz::Org::Person;

###############################################################################

=head1 Name

Bric::Biz::Org::Person - Manages Organizations Related to Persons

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  # How to create brand new Bric::Biz::Org::Person object.
  my $org = Bric::Biz::Org->lookup({ id => $org_id });
  my $porg = $org->add_object($person);

  # How to retreive existing Bric::Biz::Org::Person objects.
  my $person = Bric::Biz::Person->lookup({ id => $person_id });
  my @porgs = $person->get_orgs;

  # Other contstructors.
  my $porg = Bric::Biz::Org::Person->lookup({ id => $porg_id })
  my @porgs = Bric::Biz::Org::Person->list($search_href);

  # Class Methods.
  my @porg_ids = Bric::Biz::Org::Person->list_ids($search_href);

  # Instance Methods.
  my $id = $porg->get_id;
  my $oid = $porg->get_org_id;
  my $person = $porg->get_person;
  my $pid = $porg->get_person_id;
  my $role = $porg->get_role;
  $porg = $porg->set_role($role);
  my $title = $porg->get_title;
  $porg = $porg->set_title($title);
  my $dept = $porg->get_department;
  $porg = $porg->set_department($dept);

  $porg = $porg->activate;
  $porg = $porg->deactivate;
  $porg = $porg->is_active;

  my @addr = $porg->get_addresses;
  my $addr = $porg->new_address;
  $porg = $porg->add_addresses($addr);
  $porg = $porg->del_addresses;

  $porg = $porg->save;

=head1 Description

This class manages the association between a Bric::Biz::Person object and a
Bric::Biz::Org object. There may be numerous adddresses associated with a given
Bric::Biz::Org object, but only some of them may apply to any given person. This
class limits a Bric::Biz::Org objects addresses to those associated with a given
person. It also manages the details of the person's association with the
organization by offering properites for the person's title and department within
the organization.

When a Bric::Biz::Person object is created, it automatically has a single
Bric::Biz::Org::Person object associated with it, an object which represents the
Bric::Biz::Person object itself and the personal addresses of the person
represented. These Bric::Biz::Org::Person objects are identified by their role
properties, which will all be "Personal" by default, and by the is_persona()
method returning $self when the Org is personal, and undef whe it is not.

For example, a Bric::Biz::Peron object created for Ian Kallen will have at least
one Bric::Biz::Org::Person object, named for Ian Kallen, and in which Ian's
personal addresses may be stored. However, Ian has other addresses by his
association with the companies he works for and other organizations to which he
belongs. Thus, one can add a Bric::Biz::Org object representing About.com and then
associated create a Bric::Biz::Org::Person object by calling $org->add_object,
passing in Ian Kallen's Bric::Biz::Person object. Then one can add addresses to the
Bric::Biz::Org::Person object, either by referencing Bric::Biz::Org::Parts::Addr
object IDs, or by creating new Bric::Biz::Org::Parts::Addr objects.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Util::DBI qw(:standard);
use Bric::Util::Coll::Addr::Person;
use Bric::Util::Fault qw(throw_dp);

################################################################################
# Inheritance
################################################################################
use base qw(Bric::Biz::Org);

################################################################################
# Function and Closure Prototypes
################################################################################
my ($get_em, $get_addr_coll);

################################################################################
# Constants
################################################################################
use constant DEBUG => 0;

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields

my @PO_COLS = qw(id org__id person__id role department title active);
my @PO_PROPS= qw(id org_id person_id role department title _active);

my $SEL_COLS = 'po.id, po.org__id, po.person__id, po.role, po.department, ' .
  'po.title, po.active, o.name, o.long_name, o.personal, o.active, m.grp__id';

my @SEL_PROPS = (@PO_PROPS, qw(name long_name _personal _org_active grp_ids));

my %TXT_MAP = qw(name o.name long_name o.long_name role po.role department
                  po.department title po.title);
my %NUM_MAP = qw(id po.id org_id po.org__id person_id po.person__id);

################################################################################

################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({
                         # Public Fields
                         id =>  Bric::FIELD_READ,
                         person_id => Bric::FIELD_RDWR,
                         org_id => Bric::FIELD_RDWR,
                         role => Bric::FIELD_RDWR,
                         title => Bric::FIELD_RDWR,
                         department => Bric::FIELD_RDWR,

                         # Private Fields
                         _personal => Bric::FIELD_NONE,
                         _active => Bric::FIELD_NONE,
                         _org_active => Bric::FIELD_NONE,
                         _addr => Bric::FIELD_NONE
                        });
}

################################################################################
# Class Methods
################################################################################

=head1 Interface

=head2 Constructors

=over 4

=item $porg = Bric::Biz::Org::Person->new

=item my $porg = Bric::Biz::Org::Person->new($init)

Instantiates a Bric::Biz::Org::Person object. An anonymous hash of initial values
may be passed. The supported intial value keys are:

=over 4

=item *

org_id

=item *

name

=item *

long_name

=item *

role

=item *

person - A Bric::Biz::Person object.

=item *

obj - Alias for person.

=item *

person_id

=item *

title

=item *

department

=item *

_personal - should only be passed a true value by a call from
Bric::Biz::Person->save.

=back

Call $porg->save to save the new object.

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
    $init->{obj} ||= $init->{person};
    $init->{_personal} = ! exists $init->{_personal} ? 1
      : $init->{_personal} ? 1 : 0;
    $init->{person_id} ||= $init->{obj}->get_id if $init->{obj};
    delete @{$init}{'person', 'obj'};
    $self->SUPER::new($init);
}


################################################################################

=item my $porg = Bric::Biz::Org::Person->lookup({ id => $id })

Looks up and instantiates a new Bric::Biz::Org::Person object based on the
Bric::Biz::Org::Person object ID passed. If $id is not found in the database,
lookup() returns undef. If the ID is found more than once, lookup() returns zero
(0). This should not happen.

B<Throws:>

=over

=item *

Too many Bric::Biz::Org::Person objects found.

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

B<Side Effects:> If $id is found, populates the new Bric::Biz::Org::Person object
with data from the database before returning it.

B<Notes:> Bric::Biz::Org::Person objects have different IDs than the equivalent
Bric::Biz::Org object. The IDs vary based on the person who is associated with the
Bric::Biz::Org object.

=cut

sub lookup {
    my $pkg = shift;
    my $org = $pkg->cache_lookup(@_);
    return $org if $org;

    $org = $get_em->($pkg, @_);
    # We want @$org to have only one value.
    throw_dp(error => 'Too many Bric::Biz::Org::Person objects found.')
      if @$org > 1;
    return @$org ? $org->[0] : undef;
}

################################################################################

=item my (@porgs || $porgs_aref) = Bric::Biz::Org::Person->list($params)

Returns a list or anonymous array of Bric::Biz::Org objects based on the search
criteria passed via a hashref. The lookup searches are case-insensitive. The
supported lookup keys are:

=over 4

=item id

Person/Organization ID. May use C<ANY> for a list of possible values.

=item name

The organization's name. May use C<ANY> for a list of possible values.

=item long_name

The long name of the organization. May use C<ANY> for a list of possible
values.

=item personal

A boolean indicating whether or not the oganization is a person.

=item org_id

The organization ID, which is different from this object's ID. Yes, this is a
bad idea. May use C<ANY> for a list of possible values.

=item role

The role describing the relationship between the person and the organization.

=item person_id

The ID of the person associated with the organization. May use C<ANY> for a
list of possible values.

=item title

The person's title within the organization. May use C<ANY> for a list of
possible values.

=item department

The department the person works in. May use C<ANY> for a list of possible
values.

=item grp_id

A Bric::Util::Grp::Keyword object ID. May use C<ANY> for a list of possible
values.

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

B<Side Effects:> Populates each Bric::Biz::Org::Person object with data from the
database before returning them all.

B<Notes:> NONE.

=cut

sub list { wantarray ? @{ &$get_em(@_) } : &$get_em(@_) }

################################################################################

=back

=head2 Destructors

=over 4

=item $porg->DESTROY

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

=item my (@porg_ids || $porg_ids_aref) = Bric::Biz::Org::Person->list_ids($params)

Functionally identical to list(), but returns Bric::Biz::Org::Person object IDs rather
than objects. See list() for a description of its interface.

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

=item my $meths = Bric::Biz::Org::Person->my_meths

=item my (@meths || $meths_aref) = Bric::Biz::Org::Person->my_meths(TRUE)

=item my (@meths || $meths_aref) = Bric::Biz::Org::Person->my_meths(0, TRUE)

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

    my $ret = Bric::Biz::Org::Person->SUPER::my_meths();
    $ret->{role} = { meth => sub {shift->get_role(@_)},
                     args => [],
                     disp => 'Role',
                     type => 'short',
                     len  => 64 };
    $ret->{title} = { meth => sub {shift->get_title(@_)},
                      args => [],
                      disp => 'Title',
                      type => 'short',
                      len  => 64 };
    $ret->{department} = { meth => sub {shift->get_department(@_)},
                           args => [],
                           disp => 'Department',
                           type => 'short',
                           len  => 64 };
    return $ret;
}

################################################################################

=back

=head2 Public Instance Methods

In addition to the Public Instance Methods offered by the Bric::Biz::Org API,
Bric::Biz::Org::Person offers the following additional or overridden methods.

=over 4

=item my $id = $porg->get_id

Returns the ID of the Bric::Biz::Org::Person object. This ID will be different from
the ID of the equivalent Bric::Biz::Org object. Use the get_org_id() method to fetch
that ID.

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

B<Side Effects:> If called by Bric::Util::Grp or Bric::Util::Grp::Parts::Member
or a subclass of either, this method will return the same value as
C<get_org_id()>. This is because it is the Org ID that is used for group
membership, rather than the Org::Person ID.

B<Notes:> If the Bric::Biz::Org::Person object has been instantiated via the new()
constructor and has not yet been C<save>d, the object will not yet have an ID,
so this method call will return undef.

=cut

sub get_id {
    my $self = shift;
    # HACK. We should change it so that the person_org id is the same as the
    # org_id. Such is how User works in relation to Person. Then this method
    # wouldn't need to be written at all -- Bric.pm would handle it.
    my $caller = caller;
    if (UNIVERSAL::isa($caller, 'Bric::Util::Grp') or
        UNIVERSAL::isa($caller, 'Bric::Util::Grp::Parts::Member')) {
        # Return the org ID. Or, if there isn't one, return the ID on the
        # assumption that this method is actually being called during
        # save(), in which case the super class is adding the org to a group
        # and the id is actually the org_id, at least temporarily. See save()
        # for how the org_id and Id are juggled. Bleh!
        return $self->_get('org_id') || $self->_get('id');
    } else {
        return $self->_get('id');
    }
}

=item my $org_id = $porg->get_org_id

Returns the ID of the Bric::Biz::Org object associated with this
Bric::Biz::Org::Person object.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'org_id' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $p = $porg->get_person

Returns the Bric::Biz::Person object associated with this Bric::Biz::Org::Person
object.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_person {
    my $self = shift;
    Bric::Biz::Person->lookup({id => $self->get_id});
}

=item my $person_id = $porg->get_person_id

Returns the ID of the Bric::Biz::Person object referenced by this
Bric::Biz::Org::Person object.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'person_id' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $role = $porg->get_role

Returns the role of person represented by the Bric::Biz::Person object in the
organization represented by the Bric::Biz::Org object.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'role' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $porg->set_role($role)

Sets the role of person represented by the Bric::Biz::Person object in the
organization represented by the Bric::Biz::Org object. May be anything, such as
"Work", "Professional", etc.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'role' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $title = $porg->get_title

Returns the title of the person associated with this organization.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'title' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $porg->set_title($title)

Sets the title of the person associated with this organization.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'title' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $dept = $porg->get_dept

Returns the department of the person associated with this organization.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'dept' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $porg->set_dept($dept)

Sets the department of the person associated with this organization.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'dept' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $porg->activate

Activates the Bric::Biz::Org::Person object. Call $porg->save to make the change
persistent. Bric::Biz::Org::Person objects instantiated by new() are active by
default.

B<Throws:>

=over 4

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> Inherited from Bric::Biz::Org, but uses the active value specific
to the user, rather than the person.

B<Notes:> This method only affects the Bric::Biz::Org::Person object representing
the relationship between the underlying Bric::Biz::Org object and the
Bric::Biz::Person object.

=item $self = $porg->deactivate

Deactivates (deletes) the Bric::Biz::Org::Person object. Call $porg->save to make
the change persistent.

B<Throws:>

=over 4

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> Inherited from Bric::Biz::Org, but uses the active value specific
to the user, rather than the person.

B<Notes:> This method only affects the Bric::Biz::Org::Person object representing
the relationship between the underlying Bric::Biz::Org object and the
Bric::Biz::Person object. The underlying Bric::Biz::Org object must have its
activate() and deactivate() methods called separately from those called from a
Bric::Biz::Org::Person object.

=item $self = $porg->is_active

Returns $self if the Bric::Org::Person object is active, and undef if it is
not.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> Inherited from Bric::Biz::Org, but uses the active value specific
to the user, rather than the person.

B<Notes:> See notes for activate() and deactivate() above.

=item my (@addr || $addr_aref) = $porg->get_addr

=item my (@addr || $addr_aref) = $porg->get_addr(@address_ids)

Returns a list or anonymous array of Bric::Biz::Org::Parts::Addr objects. The
addresses returned will be a subset of those associated with the underlying
Bric::Biz::Org object, being only the organizational addresses corresponding to a
particular Bric::Biz::Person object. Returns an empty list when there are no
addresses associated with this object, and undef upon failure. See the
Bric::Biz::Org::Parts::Addr documentation for its API.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

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

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> Stores the list of Bric::Biz::Org::Parts::Addr objects internally
in the Bric::Biz::Org::Person object the first time it or any other address method
is called on a given Bric::Biz::Org::Person instance.

B<Notes:> Changes made to Bric::Biz::Org::Parts::Addr objects retreived from this
method can be persistently saved to the database only by calling the
Bric::Biz::Org::Person object's save() method.

=cut

sub get_addr {
    my $self = shift;
    my $addr_coll = &$get_addr_coll($self);
    $addr_coll->get_objs(@_);
}

=item my $address = $porg->new_addr

Adds and returns a new Bric::Biz::Org::Parts::Addr object associated with the
Bric::Biz::Org::Person object. Once $porg->save has been called, the new address will
be associated both with this Bric::Biz::Org::Person object I<and> the underlying
Bric::Biz::Org object.

Returns undef on failure. See the Bric::Biz::Org::Parts::Addr documentation for its
API.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

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

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> Stores the list of Bric::Biz::Org::Parts::Addr objects internally
in the Bric::Biz::Org object the first time it or any other address method is called on
a given Bric::Biz::Org instance.

B<Notes:> Changes made to $address objects retreived from this method can be
persistently saved to the database only by calling the Bric::Biz::Org object's save()
method.

=cut

sub new_addr {
    my $self = shift;
    my $addr_coll = &$get_addr_coll($self);
    $addr_coll->new_obj({ org_id => $self->_get('org_id') });
}

=item $self = $porg->add_addr($addr, $addr, ...)

Associates the list of Bric::Biz::Org::Parts::Addr objects with the Bric::Biz::Person
identified by the Bric::Biz::Org::Person object. The addresses must already be
associated with the underlying Bric::Biz::Org object.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

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

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> Stores the list of Bric::Biz::Org::Parts::Addr objects internally
in the Bric::Biz::Org object the first time it or any other address method is
called on a given Bric::Biz::Org instance.

B<Notes:> NONE.

=cut

sub add_addr {
    my $self = shift;
    my $addr_coll = &$get_addr_coll($self);
    my $new_addr = $addr_coll->_get('new_obj');
    push @$new_addr, @_;
}

=item $self = $porg->del_addr

=item $self = $porg->del_addr(@address_ids)

If called with no arguments, deletes all Bric::Biz::Org::Parts::Addr objects
associated with the Bric::Biz::Org::Person object. Pass Bric::Biz::Org::Parts::Addr
object IDs to delete only those Bric::Biz::Org::Parts::Addr objects.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

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

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> Deletes the Bric::Biz::Org::Parts::Addr objects from the
Bric::Biz::Org::Person object's internal structure, but retains a list of the IDs.
These will be used to delete the Bric::Biz::Org::Parts::Addr objects from the
database when $porg->save is called, then are deleted from the Bric::Biz::Org
object's internal structure. The Bric::Biz::Org::Parts::Addr objects will not
actually be deleted from the database until $porg->save is called.

B<Notes:> The addresses will not be deleted from the underlying Bric::Biz::Org
object.

=cut

sub del_addr {
    my $self = shift;
    my $addr_coll = &$get_addr_coll($self);
    $addr_coll->del_objs(@_);
}

=item $self = $porg->save

Saves any changes to the Bric::Biz::Org::Person and underlying Bric::Biz::Org objects,
including changes to associated address (Bric::Biz::Org::Parts::Addr) objects.
Returns $self on success and undef on failure.

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

B<Side Effects:> Cleans out internal cache of Bric::Biz::Org::Parts::Addr objects
to reflect what is in the database.

B<Notes:> NONE.

=cut

sub save {
    my $self = shift;
    my ($id, $addr_coll, $act) = $self->_get('id', '_addr', '_active');
    $addr_coll->save($id) if $addr_coll;
    return unless $self->_get__dirty;

    if ($id) {
        # It's an existing porg. Update it.
        $self->_set([qw(id _active)], [$self->_get(qw(org_id _org_active))]);
        $self->SUPER::save;
        $self->_set(['id', '_active'], [$id, $act]);
        local $" = ' = ?, '; # Simple way to create placeholders with an array.
        my $upd = prepare_c(qq{
            UPDATE person_org
            SET    @PO_COLS = ?
            WHERE  id = ?
        }, undef);
        execute($upd, $self->_get(@PO_PROPS), $id);
    } else {
        # It's a new porg. Insert it.
        $self->_set(['id'], [$self->_get('org_id')]);
        $self->SUPER::save;
        $self->_set([qw(org_id _org_active)], [$self->_get(qw(id _active))]);
        local $" = ', ';
        my $fields = join ', ', next_key('org'), ('?') x $#PO_COLS;
        my $ins = prepare_c(qq{
            INSERT INTO person_org (@PO_COLS)
            VALUES ($fields)
        }, undef);
        # Don't try to set ID - it will fail!
        execute($ins, $self->_get(@PO_PROPS[1..$#PO_PROPS]));
        # Now grab the ID.
        $self->_set({id => last_key('org')});
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

=item my $orgs_aref = &$get_em( $pkg, $search_href )

=item my $org_ids_aref = &$get_em( $pkg, $search_href, 1 )

Function used by lookup() and list() to return a list of Bric::Biz::Org::Person
objects or, if called with an optional third argument, returns a list of
Bric::Biz::Org::Person object IDs (used by list_ids()).

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

$get_em = sub {
    my ($pkg, $params, $ids, $href) = @_;
    my $tables = 'person_org po, org o, member m, org_member c';
    my $wheres = 'po.org__id = o.id AND o.id = c.object_id ' .
      "AND m.id = c.member__id AND m.active = '1'";
    my @params;
    while (my ($k, $v) = each %$params) {
        if ($NUM_MAP{$k}) {
            $wheres .= " AND " . any_where $v, "$NUM_MAP{$k} = ?", \@params;
        } elsif ($TXT_MAP{$k}) {
            $wheres .= " AND "
                    . any_where $v, "LOWER($TXT_MAP{$k}) LIKE LOWER(?)", \@params;
        } elsif ($k eq 'grp_id') {
            # Add in the group tables a second time and join to them.
            $tables .= ", member m2, org_member c2";
            $wheres .= " AND o.id = c2.object_id AND c2.member__id = m2.id"
              . " AND m2.active = '1' "
              . any_where $v, "AND m2.grp__id = ?", \@params;
        } elsif ($k eq 'personal') {
            # Simple boolean numeric comparison.
            $wheres .= " AND a.personal = ?";
            push @params, $v ? 1 : 0;
        }
    }

    # Make sure it's active unless and ID has been passed.
    $wheres .= "AND po.active = '1'" unless defined $params->{id};

    # Assemble and prepare the query.
    my $qry_cols = $ids ? \'DISTINCT po.id' : \$SEL_COLS;
    my $sel = prepare_c(qq{
        SELECT $$qry_cols
        FROM   $tables
        WHERE  $wheres
        ORDER BY o.id
    }, undef);

    # Just return the IDs, if they're what's wanted.
    return col_aref($sel, @params) if $ids;

    execute($sel, @params);
    my (@d, @orgs, $grp_ids);
    $pkg = ref $pkg || $pkg;
    bind_columns($sel, \@d[0..$#SEL_PROPS]);
    my $last = -1;
    while (fetch($sel)) {
        if ($d[0] != $last) {
            $last = $d[0];
            # Create a new org object.
            my $self = bless {}, $pkg;
            $self->SUPER::new;
            # Get a reference to the array of group IDs.
            $grp_ids = $d[$#d] = [$d[$#d]];
            $self->_set(\@SEL_PROPS, \@d);
            $self->_set__dirty; # Disables dirty flag.
            push @orgs, $self->cache_me;
        } else {
            push @$grp_ids, $d[$#d];
        }
    }
    return \@orgs;
};

=item my $addr_col = &$get_addr_coll($self)

Returns the collection of addresses for this organization. The collection is a
Bric::Util::Coll::Addr object. See that class and its parent, Bric::Util::Coll, for
interface details.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

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

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$get_addr_coll = sub {
    my $self = shift;
    my ($id, $addr_coll) = $self->_get('id', '_addr');
    return $addr_coll if $addr_coll;
    $addr_coll = Bric::Util::Coll::Addr::Person->new
      (defined $id ? {po_id => $id} : undef);
    $self->_set(['_addr'], [$addr_coll]);
    return $addr_coll;
};

1;
__END__

=back

=head1 Notes

This is an early draft of this class, and therefore subject to change.

=head1 Author

David Wheeler <david@justatheory.com>

=head1 See Also

L<Bric|Bric>,
L<Bric::Biz::Org|Bric::Biz::Org>,
L<Bric::Biz::Person|Bric::Biz::Person>

=cut
