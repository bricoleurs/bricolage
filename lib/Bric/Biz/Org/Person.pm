package Bric::Biz::Org::Person;
###############################################################################

=head1 NAME

Bric::Biz::Org::Person - Manages Organizations Related to Persons

=head1 VERSION

$Revision: 1.3.2.2 $

=cut

our $VERSION = (qw$Revision: 1.3.2.2 $ )[-1];

=head1 DATE

$Date: 2001-11-06 23:18:33 $

=head1 SYNOPSIS

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

=head1 DESCRIPTION

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
use Bric::Util::Fault::Exception::DP;

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

my @po_cols = qw(id org__id person__id role department title active);
my @po_props = qw(id org_id person_id role department title _active);

my @org_cols = qw(name long_name personal active);
my @org_props = qw(name long_name _personal _org_active);

my @cols = qw(po.id po.org__id po.person__id po.role po.department po.title
	      po.active o.name o.long_name o.personal o.active);

my @props = (@po_props, @org_props);

my %txt_map = qw(name o.name long_name o.long_name role po.role department
		  po.department title po.title);
my %num_map = qw(id po.id org_id po.org__id person_id po.person__id);

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

=head1 INTERFACE

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
    my $org = &$get_em(@_);
    # We want @$org to have only one value.
    die Bric::Util::Fault::Exception::DP->new({
      msg => 'Too many Bric::Biz::Org::Person objects found.' }) if @$org > 1;
    return @$org ? $org->[0] : undef;
}

################################################################################

=item my (@porgs || $porgs_aref) = Bric::Biz::Org::Person->list($params)

Returns a list or anonymous array of Bric::Biz::Org objects based on the search
criteria passed via a hashref. The lookup searches are case-insensitive. The
supported lookup keys are:

=over 4

=item *

org_id

=item *

role

=item *

person_id

=item *

title

=item *

department

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

=back 4

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

=item $meths = Bric::Biz::Org::Person->my_meths

Returns an anonymous hash of instrospection data for this object. The format for
the introspection is as follows:

Each hash key is the name of a property or attribute of the object. The value
for a hash key is another anonymous hash containing the following keys:

=over 4

=item *

meth - A reference to the method that will retrieve the value of the property
or attribute.

=item *

args - An anonymous array of arguments to pass to a call to meth in order to
retrieve the value of the property or attribute.

=item *

disp_name - The display name of the property or attribute.

=item *

type - The type of value the property or attribute contains. There are only
three types:

=over 4

=item short

=item date

=item blob

=back

=item *

length - If the value is a 'short' value, this hash key contains the length of
the field.

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub my_meths {
    # Load field members.
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

B<Side Effects:> NONE.

B<Notes:> If the Bric::Biz::Org::Person object has been instantiated via the new()
constructor and has not yet been C<save>d, the object will not yet have an ID,
so this method call will return undef.

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

Returns $self if the MPS::Org::Person object is active, and undef if it is not.

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
            SET    @po_cols = ?
            WHERE  id = ?
        }, undef, DEBUG);
	execute($upd, $self->_get(@po_props), $id);
    } else {
	# It's a new porg. Insert it.
	$self->_set(['id'], [$self->_get('org_id')]);
	$self->SUPER::save;
	$self->_set([qw(org_id _org_active)], [$self->_get(qw(id _active))]);
	local $" = ', ';
	my $fields = join ', ', next_key('org'), ('?') x $#po_cols;
	my $ins = prepare_c(qq{
            INSERT INTO person_org (@po_cols)
            VALUES ($fields)
        }, undef, DEBUG);
	# Don't try to set ID - it will fail!
	execute($ins, $self->_get(@po_props[1..$#po_props]));
	# Now grab the ID.
	$self->_set({id => last_key('org')});
    }
    $self->SUPER::save;
    return $self;
}

################################################################################

=back 4

=head1 PRIVATE

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
    my ($pkg, $args, $ids) = @_;
    my (@txt_wheres, @num_wheres, @params);
    while (my ($k, $v) = each %$args) {
	if ($num_map{$k}) {
	    push @num_wheres, $num_map{$k};
	    push @params, $v;
	} elsif ($txt_map{$k}) {
	    push @txt_wheres, "LOWER($txt_map{$k})";
	    push @params, lc $v;
	}
    }

    my $where = defined $args->{id} ? '' : 'po.active = 1 ';
    local $" = ' = ? AND ';
    $where .= $where ? "AND @num_wheres = ?" : "@num_wheres = ?" if @num_wheres;
    local $" = ' LIKE ? AND ';
    $where .= $where ? "AND @txt_wheres LIKE ?" : "@txt_wheres LIKE ?"
      if @txt_wheres;

    local $" = ', ';
    my @qry_cols = $ids ? ('id') : @cols;
    my $sel = prepare_c(qq{
        SELECT @qry_cols
        FROM   org o, person_org po
        WHERE  o.id = po.org__id
               AND $where
    }, undef, DEBUG);

    # Just return the IDs, if they're what's wanted.
    return col_aref($sel, @params) if $ids;

    execute($sel, @params);
    my (@d, @porgs);
    bind_columns($sel, \@d[0..$#cols]);
    $pkg = ref $pkg || $pkg;
    while (fetch($sel)) {
	my $self = bless {}, $pkg;
	$self->SUPER::new;
	$self->_set(\@props, \@d);
	$self->_set__dirty; # Disables dirty flag.
	push @porgs, $self
    }
    finish($sel);
    return \@porgs;
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
    $addr_coll = Bric::Util::Coll::Addr::Person->new({po_id => $id});
    $self->_set(['_addr'], [$addr_coll]);
    return $addr_coll;
};

1;
__END__

=back

=head1 NOTES

This is an early draft of this class, and therefore subject to change.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

perl(1),
Bric (2),
Bric::Biz::Org(3)
Bric::Biz::Person(4)

=cut
