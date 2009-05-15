package Bric::Biz::Org;

###############################################################################

=head1 Name

Bric::Biz::Org - Bricolage Interface to Organizations

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  # Constructors.
  my $org = Bric::Biz::Org->new;
  my $org = Bric::Biz::Org->lookup({ id => $id });
  my @orgs = Bric::Biz::Org->list($search_href);

  # Class Methods.
  my @org_ids = Bric::Biz::Org->list_ids($search_href);

  # Instance Methods.
  my $id = $org->get_id;
  my $name = $org->get_name($name);
  $org = $org->set_name($name);
  my $long_name = $org->get_long_name($long_name);
  $org = $org->set_long_name($long_name);

  $org = $org->activate;
  $org = $org->deactivate;
  $org = $org->is_active;

  my $porg = $org->add_object($person);

  my @addr = $org->get_addr;
  my $addr = $org->new_addr;
  $org = $org->del_addr;

  $org->save;

=head1 Description

This class represents organizations in Bricolage. Organizations may be the
companies for whom a person represented by a Bric::Biz::Person object works, or
an organization that owns the rights to a given asset, or with whom a product is
associated (this last use will be included in a future version).

The primary use for Bric::Biz::Org as of this writing, however, is to associate
people (Bric::Biz::Person objects) with companies and their addresses. These
associations are created by the Bric::Biz::Org add_object() method, and by the
Bric::Biz::Org::Person subclass it returns. See Bric::Biz::Org::Person for its
additions to the Bric::Biz::Org API.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Util::DBI qw(:standard col_aref);
use Bric::Util::Coll::Addr;
use Bric::Util::Grp::Org;
use Bric::Util::Fault qw(throw_dp);

################################################################################
# Inheritance
################################################################################
use base qw(Bric);

################################################################################
# Function and Closure Prototypes
################################################################################
my ($get_em, $get_addr_coll);

################################################################################
# Constants
################################################################################
use constant DEBUG => 0;
use constant GROUP_PACKAGE => 'Bric::Util::Grp::Org';
use constant INSTANCE_GROUP_ID => 3;

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields
my @COLS = qw(id name long_name personal active);
my @PROPS = qw(id name long_name _personal _active);

my $SEL_COLS = 'a.id, a.name, a.long_name, a.personal, a.active, m.grp__id';
my @SEL_PROPS = (@PROPS, 'grp_ids');

my @ORD = qw(name long_name active);
my $METHS;

################################################################################

################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({
                         # Public Fields
                         id =>  Bric::FIELD_READ,
                         name => Bric::FIELD_RDWR,
                         long_name => Bric::FIELD_RDWR,
                         grp_ids => Bric::FIELD_READ,

                         # Private Fields
                         _personal => Bric::FIELD_NONE,
                         _active => Bric::FIELD_NONE,
                         _addr => Bric::FIELD_NONE
                        });
}

################################################################################
# Class Methods
################################################################################

=head1 Interface

=head2 Constructors

=over 4

=item $org = Bric::Biz::Org->new

=item my $org = Bric::Biz::Org->new($init)

Instantiates a Bric::Biz::Org object. A hashref of initial values may be passed. The
supported intial value keys are:

=over 4

=item *

name

=item *

long_name

=back

Call $org->save to save the new object.

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
    $init->{_personal} = $init->{_personal} ? 1 : 0;
    $init->{_active} = 1;
    push @{$init->{grp_ids}}, INSTANCE_GROUP_ID;
    $self->SUPER::new($init);
}


################################################################################

=item my $org = Bric::Biz::Org->lookup({ id => $id })

Looks up and instantiates a new Bric::Biz::Org object based on the Bric::Biz::Org
object ID passed. If $id is not found in the database, lookup() returns
undef. If the ID is found more than once, lookup() throws an exception. This
should not happen.

B<Throws:>

=over 4

=item *

Too many Bric::Biz::Org objects found.

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

B<Side Effects:> If $id is found, populates the new Bric::Biz::Org object with data
from the database before returning it.

B<Notes:> NONE.

=cut

sub lookup {
    my $pkg = shift;
    my $org = $pkg->cache_lookup(@_);
    return $org if $org;

    $org = $get_em->($pkg, @_);
    # We want @$org to have only one value.
    throw_dp(error => 'Too many Bric::Biz::Org objects found.') if @$org > 1;
    return @$org ? $org->[0] : undef;
}

################################################################################

=item my (@orgs || $orgs_aref) = Bric::Biz::Org->list($params)

Returns a list or anonymous array of Bric::Biz::Org objects based on the search
criteria passed via a hashref. The lookup searches are case-insensitive. The
supported lookup parameter keys are:

=over 4

=item id

Organization ID. May use C<ANY> for a list of possible values.

=item name

The organization's name. May use C<ANY> for a list of possible values.

=item long_name

The long name of the organization. May use C<ANY> for a list of possible
values.

=item personal

A boolean indicating whether or not the oganization is a person.

=item grp_id

A Bric::Util::Grp::Keyword object ID. May use C<ANY> for a list of possible
values.

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

B<Side Effects:> Populates each Bric::Biz::Org object with data from the database
before returning them all.

B<Notes:> This method is overridden by the list() method of the
Bric::Biz::Org::Person class.

=cut

sub list { wantarray ? @{ &$get_em(@_) } : &$get_em(@_) }

################################################################################

=back

=head2 Destructors

=over 4

=item $org->DESTROY

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

=item my (@org_ids || $org_ids_aref) = Bric::Biz::Org->list_ids($params)

Functionally identical to list(), but returns Bric::Biz::Org object IDs rather than
objects. See list() for a description of its interface.

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

=item $meths = Bric::Biz::Org >my_meths

=item (@meths || $meths_aref) = Bric::Biz::Org->my_meths(TRUE)

=item my (@meths || $meths_aref) = Bric::Biz::Org->my_meths(0, TRUE)

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
    return !$ord ? $METHS : wantarray ? @{$METHS}{@ORD} : [@{$METHS}{@ORD}]
      if $METHS;

    # We don't got 'em. So get 'em!
    $METHS = {
              name      => {
                            name     => 'name',
                            get_meth => sub { shift->get_name(@_) },
                            get_args => [],
                            set_meth => sub { shift->set_name(@_) },
                            set_args => [],
                            disp     => 'Name',
                            type     => 'short',
                            len      => 64,
                            req      => 1,
                            search   => 1,
                            props    => { type       => 'text',
                                          length     => 32,
                                          maxlength => 64
                                        }
                           },
              long_name => {
                             name     => 'long_name',
                             get_meth => sub { shift->get_long_name(@_) },
                             get_args => [],
                             set_meth => sub { shift->set_long_name(@_) },
                             set_args => [],
                             disp     => 'Long name',
                             search   => 1,
                             len      => 128,
                             req      => 0,
                             type     => 'short',
                             props    => { type      => 'text',
                                           length    => 32,
                                           maxlength => 128
                                         }
                            },
              active    => {
                            name     => 'active',
                            get_meth => sub { shift->is_active(@_) ? 1 : 0 },
                            get_args => [],
                            set_meth => sub { $_[1] ? shift->activate(@_)
                                                : shift->deactivate(@_) },
                            set_args => [],
                            disp     => 'Active',
                            search   => 0,
                            len      => 1,
                            req      => 1,
                            type     => 'short',
                            props    => { type => 'checkbox' }
                           },
             };
    return !$ord ? $METHS : wantarray ? @{$METHS}{@ORD} : [@{$METHS}{@ORD}];
}

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item my $id = $org->get_id

Returns the ID of the Bric::Biz::Org object.

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

B<Notes:> If the Bric::Biz::Org object has been instantiated via the new()
constructor and has not yet been C<save>d, the object will not yet have an ID,
so this method call will return undef.

=item my $name = $org->get_name

Returns the common name for the Bric::Biz::Org object.

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

=item $self = $org->set_name($name)

Sets the common name of the Bric::Biz::Org object. Returns $self on success and undef
on failure.

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

=item my $long_name = $org->get_long_name

Returns the formal name for the Bric::Biz::Org object.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'long_name' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $org->set_long_name($long_name)

Sets the formal name for the Bric::Biz::Org object. Returns $self on success And Undef
on failure

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: WRITE access for field 'long_name' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $org->activate

Activates the Bric::Biz::Org object. Call $org->save to make the change persistent.
Bric::Biz::Org objects instantiated by new() are active by default.

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

=item $self = $org->deactivate

Deactivates (deletes) the Bric::Biz::Org object. Call $org->save to make the change
persistent.

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

=item $self = $org->is_active

Returns $self if the Bric::Biz::Org object is active, and undef if it is not.

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

=item $self = $org->is_personal

Returns $self if the Bric::Biz::Org object is personal, and undef if it is not. By
personal I mean that it is directly related to an individual person, and all the
addresses are associated with that person. This setting cannot be changed; it is
set to true for the personal organization created for a person whenever a person
is created.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub is_personal {
    my $self = shift;
    $self->_get('_personal') ? $self : undef;
}

=item my $obj_org = $org->add_object($object)

Associates a Bricolage object with the Bric::Biz::Org object, returning the relevant
subclassed Bric::Biz::Org object. See the Bric::Biz::Org::* subclasses for the
relevant methods for associating specific Bric::Biz::Org::Parts::Addresses with
other Bricolage objects.

B<Throws:>

=over 4

=item *

Unable to instantiate new object.

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> Returns a subclassed Bric::Biz::Org object with methods for
managing the association with the Bricolage object. Currently, only Bric::Biz::Person
objects may be passed, thus returning Bric::Biz::Org::Person objects.

B<Notes:> NONE.

=cut

sub add_object {
    my $self = shift;
    my $obj = shift;
    (my $class = ref $obj) =~ s/^.*:(\w+)$/$1/;
    $class = "Bric::Biz::Org::$class";
    my (%init, $ret);
    @init{qw(name long_name org_id obj)} =
      ($self->_get(qw(name long_name id)), $obj);
    eval { $ret = $class->new(\%init) };
    throw_dp(error => "Unable to instantiate new $class object: $@.") if $@;
    return $ret;
}

=item my (@addr || $addr_aref) = $org->get_addr

=item my (@addr || $addr_aref) = $org->get_addr(@address_ids)

Returns a list of Bric::Biz::Org::Parts::Address objects. Returns an empty list when
there are no addresses associated with this object, and undef upon failure. See
the Bric::Biz::Org::Parts::Address documentation for its API.

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

B<Side Effects:> Stores the list of Bric::Biz::Org::Parts::Address objects
internally in the Bric::Biz::Org object the first time it or any other address
method is called on a given Bric::Biz::Org instance.

B<Notes:> Changes made to Bric::Biz::Org::Parts::Address objects retreived from
this method can be persistently saved to the database only by calling the
Bric::Biz::Org object's save() method.

=cut

sub get_addr { &$get_addr_coll(shift)->get_objs(@_) }

=item my $address = $org->new_addr

Adds and returns a new Bric::Biz::Org::Parts::Address object associated with
the Bric::Biz::Org object. Pass in an optional list of parameters for
attributes to be assigned to the object. Returns C<undef> on failure. See
L<Bric::Biz::Org::Parts::Address|Bric::Biz::Org::Parts::Address> for its API.

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

B<Side Effects:> Uses Bric::Util::Coll internally.

B<Notes:> Changes made to $address objects retreived from this method can be
persistently saved to the database only by calling the Bric::Biz::Org object's
save() method.

=cut

sub new_addr {
    my ($self, $params) = @_;
    $params->{org_id} = $self->_get('id');
    $get_addr_coll->($self)->new_obj($params);
}

=item my $self = $org->del_addr

=item my $self = $org->del_addr(@address_ids)

If called with no arguments, deletes all Bric::Biz::Org::Parts::Address objects
associated with the Bric::Biz::Org object. Pass Bric::Biz::Org::Parts::Address object
IDs to delete only those Bric::Biz::Org::Parts::Address objects.

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

B<Side Effects:> Deletes the Bric::Biz::Org::Parts::Address objects from the
Bric::Biz::Org object's internal structure, but retains a list of the IDs. These
will be used to delete the Bric::Biz::Org::Parts::Address objects from the database
when $org->save is called, then are deleted from the Bric::Biz::Org object's
internal structure. The Bric::Biz::Org::Parts::Address objects will not actually be
deleted from the database until $org->save is called.

B<Notes:> If called with a list of Bric::Biz::Org::Parts::Address object IDs,
del_address() will only delete those address object if they're associated with
the current Bric::Biz::Org object.

=cut

sub del_addr { &$get_addr_coll(shift)->del_objs(@_) }

=item $self = $org->save

Saves any changes to the Bric::Biz::Org object, including changes to associated address
(Bric::Biz::Org::Parts::Address) objects. Returns $self on success and undef on
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

B<Side Effects:> Cleans out internal cache of Bric::Biz::Org::Parts::Address objects to
reflect what is in the database.

B<Notes:> NONE.

=cut

sub save {
    my $self = shift;
    my ($id, $addr_coll) = $self->_get('id', '_addr');
    $addr_coll->save if $addr_coll;
    return $self unless $self->_get__dirty;

    if (defined $id) {
        # It's an existing org. Update it.
        local $" = ' = ?, '; # Simple way to create placeholders with an array.
        my $upd = prepare_c(qq{
            UPDATE org
            SET   @COLS = ?
            WHERE  id = ?
        }, undef);
        execute($upd, $self->_get(@PROPS, 'id'));
        unless ($self->_get('_active')) {
            # Deactivate all group memberships if we've deactivated the org.
            foreach my $grp (Bric::Util::Grp::Org->list
                             ({ obj => $self, permanent => 0 })) {
                foreach my $mem ($grp->has_member({ obj => $self })) {
                    next unless $mem;
                    $mem->deactivate;
                    $mem->save;
                }
            }
        }
    } else {
        # It's a new org. Insert it.
        local $" = ', ';
        my $fields = join ', ', next_key('org'), ('?') x $#COLS;
        my $ins = prepare_c(qq{
            INSERT INTO org (@COLS)
            VALUES ($fields)
        }, undef);
        # Don't try to set ID - it will fail!
        execute($ins, $self->_get(@PROPS[1..$#PROPS]));
        # Now grab the ID.
        $id = last_key('org');
        $self->_set(['id'], [$id]);

        # And finally, add this org to the "All Organizations" group.
        $self->register_instance(INSTANCE_GROUP_ID, GROUP_PACKAGE);
    }
    $self->SUPER::save;
    return $self;
}

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

Function used by lookup() and list() to return a list of Bric::Biz::Org objects or,
if called with an optional third argument, returns a list of Bric::Biz::Org object
IDs (used by list_ids()).

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
    my $tables = 'org a, member m, org_member c';
    my $wheres = 'a.id = c.object_id AND m.id = c.member__id '
      . "AND m.active = '1'";
    my @params;
    while (my ($k, $v) = each %$params) {
        if ($k eq 'id') {
            # Simple numeric comparison.
            $wheres .= " AND " . any_where($v, "a.id = ?", \@params);
        } elsif ($k eq 'personal') {
            # Simple boolean numeric comparison.
            $wheres .= " AND a.personal = ?";
            push @params, $v ? 1 : 0;
        } elsif ($k eq 'grp_id') {
            # Add in the group tables a second time and join to them.
            $tables .= ", member m2, org_member c2";
            $wheres .= " AND a.id = c2.object_id AND c2.member__id = m2.id"
              . " AND m2.active = '1' AND "
              . any_where($v, "m2.grp__id = ?", \@params);
        } else {
            # Simple string comparison.
            $wheres .= " AND "
              . any_where($v, "LOWER(a.$k) LIKE LOWER(?)", \@params);
        }
    }

    # Make sure it's active unless and ID has been passed.
    $wheres .= "AND a.active = '1'" unless defined $params->{id};

    # Assemble and prepare the query.
    my ($qry_cols, $order) = $ids ? (\'DISTINCT a.id', 'a.id') :
      (\$SEL_COLS, 'a.personal, a.long_name, a.id');
    my $sel = prepare_c(qq{
        SELECT $$qry_cols
        FROM   $tables
        WHERE  $wheres
        ORDER BY $order
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
    $addr_coll = Bric::Util::Coll::Addr->new
      ( defined $id ? {org_id => $id} : undef );
    $self->_set(['_addr'], [$addr_coll]);
    return $addr_coll;
};

1;
__END__

=back

=head1 Notes

NONE.

=head1 Author

David Wheeler <david@justatheory.com>

=head1 See Also

L<Bric|Bric>,
L<Bric::Biz::Person|Bric::Biz::Person>

=cut
