package Bric::Biz::Org::Parts::Addr;

###############################################################################

=head1 Name

Bric::Biz::Org::Parts::Addr - Organizational Addresses

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  # Constructors are private - construct from Bric::Biz::Org objects.
  my $org = Bric::Biz::Org->lookup({ id => $org_id });
  my @addr = $org->get_addresses;
  my $addr = $org->new_address;

  # Instance Methods.
  my $id $addr->get_id;
  my $type = $addr->get_type;
  $addr = $addr->set_type($type);
  my $city = $addr->get_city;
  $addr = $addr->set_city($city);
  my $state = $addr->get_state;
  $addr = $addr->set_state($state);
  my $code = $addr->get_code;
  $addr = $addr->set_code($code);
  my $country = $addr->get_country;
  $addr = $addr->set_country($country);
  my @lines = $addr->get_lines;
  $addr = $addr->set_lines(@lines);

  $addr = $addr->activate;
  $addr = $addr->deactivate;
  $addr = $addr->is_active;

  # Print Address Labels.
  my $p = Bric::Biz::Person->lookup({ id => $person_id });
  foreach my $porg ($p->get_orgs) {
      foreach my $addr ($porg->get_addresses($id)) {
          print $p->format_name("%f% M% l"), "\n";
          print $porg->title, "\n" if $porg->title;
          print $porg->dept, "\n" if $porg->dept;
          map { print "$_\n" } $addr->get_lines;
          print $addr->get_city, ", ", $addr->get_state, "\n";
          print $addr->get_code, "  ", $addr->get_country, "\n\n";
      }
  }

=head1 Description

This class represents organizational addresses as objects. Organizations are
represented as Bric::Biz::Org or subclassed Bric::Biz::Org objects, and a given
Bric::Biz::Org object may have an unlimited number of addresses associated with it,
each represented by a Bric::Biz::Org::Parts::Addr object.

Bric::Biz::Org::Parts::Addr objects can only be instantiated via the Bric::Biz::Org
get_addresses() or add_address() method calls. The Bric::Biz::Org::Parts::Addr
constructors are therefore private.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Bric::Util::DBI qw(:standard col_aref prepare_ca);
use Bric::Util::Fault qw(throw_gen throw_dp);

################################################################################
# Inheritance
################################################################################
use base qw(Bric);

################################################################################
# Function Prototypes
################################################################################
my ($get_em, $make_obj, $get_part, $set_part, $save_main, $save_parts,
    $save_lines, $part_sql);

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
my @cols = qw(a.id a.org__id a.type a.active p.id t.name p.value);
my @props = qw(id org_id type active);
my @ins_cols = qw(id org__id type active);
my @part_cols = qw(id name value);

################################################################################

################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({
                         # Public Fields
                         id =>  Bric::FIELD_READ,
                         org_id => Bric::FIELD_READ,
                         type => Bric::FIELD_RDWR,
                         active => Bric::FIELD_NONE,
                         parts => Bric::FIELD_READ,

                         # Private Fields
                         _lines => Bric::FIELD_NONE,
                         _part_ids => Bric::FIELD_NONE,
                         _flags => Bric::FIELD_NONE
                        });
}

################################################################################
# Class Methods
################################################################################

=head1 Interface

=head2 Constructors

=over 4

=item $addr = Bric::Biz::Org::Parts::Addr->new($init)

Instantiates a Bric::Biz::Org::Parts::Addr object. A hashref of initial values may
be passed. The supported initial value keys are:

=over

=item *

org_id

=item *

type

=item *

city

=item *

state

=item *

code

=item *

country

=item *

lines

=back

If lines is passed, a single line may be passed, and multiple lines may be
passed as an anonymous array. Call $add->_save to save the new object.

B<Throws:>

=over 4

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> To be called from Bric::Biz::Org only.

=cut

sub new {
    my ($pkg, $args) = @_;
    # Grab the org_id and type.
    my $init = { org_id => $args->{org_id}, type => $args->{type} };
    # Grab lines.
    if ($args->{lines}) {
        $init->{_flags}{__lines__} = 1;
        $init->{_lines}{_add} = ref $args->{lines} ? $args->{lines}
                                                   : [$args->{lines}];
    }

    my %ignore = map { $_ => undef } qw(org_id type lines);
    # The remaining keys are parts, and need to be stored in proper case.
    foreach my $part (keys %$args) {
        next if exists $ignore{$part};
        my $p = ucfirst $part;
        $init->{parts}{$p} = $args->{$part};
        push @{ $init->{_flags}{__parts__} }, $p;
    }

    # Set the active flag and all other flags.
    $init->{active} = 1;
    $init->{_flags}{__main__} = 1;

    # Create and initialize the object.
    my $self = bless {}, ref $pkg || $pkg;
    $self->SUPER::new($init);
    return $self;
}


################################################################################

=item my $addr = Bric::Biz::Org::Parts::Addr->lookup({ id => $id })

Looks up and instantiates a new Bric::Biz::Org::Parts::Addr object based on the
Bric::Biz::Org::Parts::Addr object ID passed. If $id is not found in the database,
lookup() returns undef. If the ID is found more than once, lookup() returns
zero (0). This should not happen.

B<Throws:>

=over 4

=item *

Too many Bric::Biz::Org::Parts::Addr objects found.

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

B<Side Effects:> If $id is found, populates the new Bric::Biz::Org object with data
from the database before returning it.

B<Notes:> There may actually be no use for this method, since
Bric::Biz::Org::Parts::Addr objects will be stored internally in a Bric::Biz::Org
object, and therefore may not need to be implemented.

=cut

sub lookup {
    my $pkg = shift;
    my $addr = $pkg->cache_lookup(@_);
    return $addr if $addr;

    $addr = $get_em->($pkg, @_);
    # We want @$addr to have only one value.
    throw_dp(error => 'Too many Bric::Biz::Org::Parts::Addr objects found.')
      if @$addr > 1;
    return @$addr ? $addr->[0] : undef;
}

################################################################################

=item my (@orgs || $orgs_aref) = Bric::Biz::Org::Parts::Addr->list($params)

Returns a list of Bric::Biz::Org::Parts::Addr objects based on the search criteria
passed via a hashref. The lookup searches are case-insensitive. The supported
lookup parameter keys are:

=over

=item id

Address ID. May use C<ANY> for a list of possible values.

=item type

The type of address. May use C<ANY> for a list of possible values.

=item city

The address city. May use C<ANY> for a list of possible values.

=item state

The address state. May use C<ANY> for a list of possible values.

=item code

The address postal code. May use C<ANY> for a list of possible values.

=item country

The address country. May use C<ANY> for a list of possible values.

=item org_id

The ID for a Bric::Biz::Org object with which addresses may be associated. May
use C<ANY> for a list of possible values.

=item person_id

The ID of a Bric::Biz::Person object with which addresses may be associated.
May use C<ANY> for a list of possible values.

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

B<Side Effects:> Populates each Bric::Biz::Org::Parts::Addr object with data from
the database before returning them all. To be called from Bric::Biz::Org only.

B<Notes:> NONE.

=cut

sub list { wantarray ? @{ &$get_em(@_) } : &$get_em(@_) }

################################################################################

=item Bric::Biz::Org::Parts::Addr->href($params)

Exactly the same as list(), except that it returns all the
Bric::Biz::Org::Parts::Addr objects in an anonymous hash, where the hash keys are
the object IDs and the values are the objects. See list() for syntax.

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

sub href { &$get_em(@_, 0, 1) }

################################################################################

=back

=head2 Destructors

=over 4

=item $addr->DESTROY

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

=item my (@aids || $aids_aref) = Bric::Biz::Org::Parts::Addr->list_ids($params)

Returns a list or anonymous array of Bric::Biz::Org::Parts::Addr object IDs based
on the search criteria passed. The search parameters are the same as those for
list() above.

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

=item my (@parts || $parts_aref) Bric::Biz::Org::Parts::Addr->list_parts

Returns a list of active address parts.

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

sub list_parts {
    my $sel = prepare_ca(qq{
        SELECT name
        FROM   addr_part_type
        WHERE  active = '1'
        ORDER BY id
    }, undef);
    return wantarray ? @{ col_aref($sel) } : col_aref($sel);
}

=item $success = Bric::Biz::Org::Parts::Addr->add_parts(@parts)

Adds new address parts to the Bric::Biz::Org::Parts::Addr object. These parts
will be available exclusively through the get_parts() instance method.

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub add_parts {
    my $pkg = shift;
    my $upd = prepare_c(qq{
        UPDATE addr_part_type
        SET    active = ?
        WHERE  name = ?
    }, undef);

    my $ins = prepare_c(qq{
        INSERT INTO addr_part_type (id, name, active)
        VALUES (${ \next_key('addr_part_type') }, ?, 1)
    }, undef);

    foreach my $part (@_) {
        execute($ins, $part) if execute($upd, 1, $part) eq '0E0';
    }
    return 1;
}

=item $success = Bric::Biz::Org::Parts::Addr->del_parts(@parts)

Deletes address parts.

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub del_parts {
    my $pkg = shift;

    my $upd = prepare_c(qq{
        UPDATE addr_part_type
        SET    active = ?
        WHERE  name = ?
    }, undef);

    foreach my $line (@_) {
        # Throw an error here!
        throw_gen(error => "Cannot delete the 'Line' address part")
          if $line eq 'Line';
        execute($upd, 0, $line);
    }
    return 1;
}

################################################################################

=item my $meths = Bric::Biz::Org::Parts::Addr->my_meths

=item my (@meths || $meths_aref) = Bric::Biz:::Org::Parts::Addr->my_meths(TRUE)

=item my (@meths || $meths_aref) = Bric::Biz:::Org::Parts::Addr->my_meths(0, TRUE)

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

    my $ret = { type    => { meth => sub {shift->get_type(@_)},
                             args => [],
                             disp => 'Type',
                             type => 'short',
                             len  => 64 },
                city    => { meth => sub {shift->get_city(@_)},
                             args => [],
                             disp => 'City',
                             type => 'short',
                             len  => 256 },
                state   => { meth => sub {shift->get_state(@_)},
                             args => [],
                             disp => 'State',
                             type => 'short',
                             len  => 256 },
                code    => { meth => sub {shift->get_code(@_)},
                             args => [],
                             disp => 'Code',
                             type => 'short',
                             len  => 256 },
                country => { meth => sub {shift->get_country(@_)},
                             args => [],
                             disp => 'Country',
                             type => 'short',
                             len  => 256 }
              };
    return $ret;
}

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item my $id = $addr->get_id

Returns the ID of the Bric::Biz::Org::Parts::Addr object.

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

B<Notes:> If the Bric::Biz::Org::Parts::Addr object has been instantiated via the
new() private constructor and has not yet been saved, via the Bric::Biz::Org
save() method, the object will not yet have an ID, so this method call will
return undef.

=item my $type = $addr->get_type

Returns the type of address it is. Intended to distinguish between different
addresses for a given organization. Examples might be "New York Shipping" or
"San Francisco Billing."

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

=item $self = $addr->set_type($type)

Sets the type attributte. Returns $self on success and undef on failure.

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

B<Notes:> NONE.

=cut

sub set_type {
    my $self = shift;
    my $flags = $self->_get('_flags');
    $flags->{__main__} = 1;
    $self->_set(['type', '_flags'], [shift, $flags]);
}

=item my $ = $addr->get_city

Returns the address city.

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

B<Notes:> NONE.

=cut

sub get_city { &$get_part($_[0], 'City') }

=item $self = $addr->set_city($city)

Sets the address city. Returns $self on success and undef on failure.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_city { &$set_part($_[0], 'City', $_[1]); }

=item my $state = $addr->get_state

Returns the address state.

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

B<Notes:> NONE.

=cut

sub get_state { &$get_part($_[0], 'State') }

=item $self = $addr->set_state($state)

Sets the address state. Returns $self on success and undef on failure.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_state { &$set_part($_[0], 'State', $_[1]); }

=item my $code = $addr->get_code

Returns the address postal code, such as US Zip Code.

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

B<Notes:> NONE.

=cut

sub get_code { &$get_part($_[0], 'Code') }

=item $self = $addr->set_code($code)

Sets the address postal code, such as US Zip Code. Returns $self on success and
undef on failure.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_code { &$set_part($_[0], 'Code', $_[1]); }

=item my $country = $addr->get_country

Returns the addresse country.

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

B<Notes:> NONE.

=cut

sub get_country { &$get_part($_[0], 'Country') }

=item $self = $addr->set_country($country)

Sets the address country. Returns $self on success and undef on failure.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> Countries are stored in the database by their ISO 3166 code names. See
http://wmbr.mit.edu/stations/ISOcodes.html. We'll need to finagle some sort of
database lookup, perhaps through a trigger.

=cut

sub set_country { &$set_part($_[0], 'Country', $_[1]); }

=item my @lines = $addr->get_lines

Returns an ordered list of individual address lines for the addres. An infinite
number of address lines are supported, though it is assumed that most addresses
will have 1-3 address lines.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_lines {
    my $self = shift;
    my $lines = $self->_get('_lines');
    my @lines;
    foreach my $id (sort keys %$lines) {
        next if $id eq '_del' || $id eq '_dirty';
        if ($id eq '_add') {
            push @lines, @{ $lines->{_add} };
        } else {
            push @lines, $lines->{$id};
        }
    }
    return wantarray ? @lines : \@lines;
}

=item $self = $addr->set_lines(@lines)

Sets the address lines for the address. An infinite number of address lines are
supported, though it is assumed that most addresses will have 1-3 address lines.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> Stores new address lines internally to the object. The lines
will not persist until the address object is saved via the Bric::Biz::Org object's
save() method.

B<Notes:> NONE.

=cut

sub set_lines {
    my $self = shift;
    my ($lines, $flags) = $self->_get('_lines', '_flags');
    foreach my $id (sort keys %$lines) {
        if (@_) {
            # Assign the line.
            $lines->{$id} = shift;
        } else {
            # Delete the line.
            delete $lines->{$id};
            push @{ $lines->{_del} }, $id;
        }
    }
    foreach my $l (@_) {
        # We'll need to add this line.
        push @{ $lines->{_add} }, $l;
    }
    # Set a flag so we know we've got work to do to save the lines!
    $flags->{__lines__} = 1;
    $self->_set(['_lines', '_flags'], [$lines, $flags]);
}

=item my (%parts || $parts_href) = $addr->get_parts;

Returns a hash (list) or anonymous hash of the parts of this address.

B<Throws:>

=over 4

=item *

Bad AUTOLOAD method format.

=item *

Cannot AUTOLOAD private methods.

=item *

Access denied: READ access for field 'parts' required.

=item *

No AUTOLOAD method.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $self = $addr->set_part($part, $value);

Sets a part to a value. The part must exist in the database. To add a part,
use the add_parts() class method.

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

B<Notes:> I could grab a list of all the parts from the database here (using
list_parts() and then make sure each part exists before assigning it, but I
didn't want to waste the query. Instead, there'll be a failure when save() is
called and there's a non-valid part name.

=cut

sub set_part { &$set_part(@_) }

=item $self = $addr->activate

Activates the Bric::Biz::Org::Parts::Addr object. The change will not persist until
the Bric::Biz::Org object's save() method is called. Bric::Biz::Org::Parts::Addr
objects instantiated by new() are active by default.

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
    $self->_set({active => 1 });
}

=item $self = $addr->deactivate

Deactivates (deletes) the Bric::Biz::Org::Parts::Addr object. The change will not
persist until the Bric::Biz::Org object's save() method is called.

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
    $self->_set({active => 0 });
}

=item $self = $addr->is_active

Returns $self if the Bric::Biz::Org::Parts::Addr object is active, and undef if it
is not.

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
    $self->_get('active') ? $self : undef;
}

=item $self = $addr->save

Saves any changes to the Bric::Biz::Org::Parts::Addr object, including changes to
associated address (Bric::Biz::Org::Parts::Addr) objects. Returns $self on success
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

B<Side Effects:> Cleans out internal cache of address lines and parts to reflect
what is in the database.

B<Notes:> NONE.

=cut

sub save {
    my $self = shift;
    return $self unless $self->_get__dirty;
    my $flags = $self->_get('_flags');
    &$save_main($self) if $flags->{__main__};
    &$save_parts($self, $flags->{__parts__}) if $flags->{__parts__};
    &$save_lines($self) if $flags->{__lines__};
    %$flags = ();
    $self->SUPER::save;
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
    my ($pkg, $args, $ids, $href) = @_;
    my $tables = "addr a, addr_part_type t, addr_part p";
    my (@wheres, @params);
    while (my ($k, $v) = each %$args) {
        if ($k eq 'id') {
            # We're looking for a specific ID.
            push @wheres, any_where $v, "a.id = ?", \@params;
        } elsif ($k eq 'org_id') {
            # We're looking for a Bric::Biz::Org object ID.
            push @wheres, any_where $v, "a.org__id = ?", \@params;
        } elsif ($k eq 'type') {
            # We're looking for a specific type of address.
            push @wheres, any_where $v, "LOWER(a.$k) LIKE LOWER(?)", \@params;
        } elsif ($k eq 'po_id') {
            # We're looking for addresses associated with a Org::Person object.
            $tables .= ", person_org__addr poa";
            push @wheres, "a.id = poa.addr__id",
              any_where $v, "poa.person_org__id = ?", \@params;
        } elsif ($k eq 'person_id') {
            # We're looking for addresses associated with a Org::Person object.
            $tables .= ', person_org po';
            push @wheres, "a.org__id = po.org__id",
              any_where $v, "po.person__id = ?", \@params;
        } else {
            # We're interested in some other part of the address.
            $tables .= ', addr_part ap, addr_part_type pt';
            push @params, $k;
            push @wheres, 'a.id = ap.addr__id',
                          'pt.id = ap.addr_part_type__id',
                          '(LOWER(pt.name) LIKE LOWER(?) AND '
                            . any_where(
                                $v,
                                'LOWER(ap.value) LIKE LOWER(?)',
                                \@params
                            )
                            . ')';
        }
    }

    # Make sure the records are active unless an ID is specified.
    unshift @wheres, "a.active = '1'" unless defined $args->{id};

    # Put together the where statement.
    my $where = join ' AND ', @wheres;

    # Assemble the final query!
    my ($here_cols, $order_by) = $ids
        ? ('DISTINCT a.id', 'a.id')
        : (join(', ', @cols), 'a.id, p.id');
    my $sel = prepare_c(qq{
        SELECT $here_cols
        FROM   $tables
        WHERE  a.id = p.addr__id
               AND t.id = p.addr_part_type__id
               AND $where
        ORDER BY $order_by
    }, undef);

    # Just return the IDs, if they're what's wanted.
    return col_aref($sel, @params) if $ids;

    execute($sel, @params);
    my (@d, @a, @addrs, %obj, %addrs);
    bind_columns($sel, \@d[0..$#props], \@a[0..$#part_cols]);
    $pkg = ref $pkg || $pkg;

    while (fetch($sel)) {
        @obj{@props} = @d unless $obj{id};
        if ( $d[0] != $obj{id} ) {
            # It's a new object. Save the last one.
            $href ? $addrs{$obj{id}} = &$make_obj($pkg, \%obj)
              : push @addrs, &$make_obj($pkg, \%obj);
            # Now grab the new object.
            %obj = ();
            @obj{@props} = @d;
        }

        # Grab any parts. These will vary from row to row.
        if ($a[0]) {
            if ($a[1] eq 'Line') {
                # Lines go in their own property space.
                $obj{_lines}->{$a[0]} = $a[2];
            } else {
                # Other parts go in a separate space from lines.
                $obj{parts}->{$a[1]} = $a[2];
                $obj{_part_ids}->{$a[1]} = $a[0];
            }
        }
    }
    # Grab the last one!
    $href ? $addrs{$obj{id}} = &$make_obj($pkg, \%obj)
      : push @addrs, &$make_obj($pkg, \%obj) if %obj;
    finish($sel);
    return $href ? \%addrs : \@addrs;
};

=item my $addr = &$make_obj($pkg, $init)

Instantiates a new object.

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

$make_obj = sub {
    my ($pkg, $init) = @_;
    my $self = bless {}, $pkg;
    $self->SUPER::new($init);
    $self->_set__dirty; # Disables dirty flag.
    return $self->cache_me;
};

=item $self = &$set_part($self, $part, $value)

Sets an address part.

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

B<Notes:> NONE.

=cut

$set_part = sub {
    my $self = shift;
    my ($parts, $flag) = $self->_get('parts', '_flags');
    $parts->{$_[0]} = $_[1];
    push @{ $flag->{__parts__} }, $_[0];
    $self->_set(['_flags', 'parts'], [$flag, $parts]);
};

=item $self = &$get_part($self, $part)

Gets an address part.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$get_part = sub {
    my $self = shift;
    return $self->_get('parts')->{$_[0]};
};

=item $success = &$save_main($self)

Saves the primary properties of the object.

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

$save_main = sub {
    my $self = shift;
    my $id = $self->_get('id');
    if (defined $id) {
        # It's an existing record. Update it.
        local $" = ' = ?, '; # Simple way to create placeholders.
        my $upd = prepare_c(qq{
            UPDATE addr
            SET    @ins_cols = ?
            WHERE  id = ?
        }, undef);
        execute($upd, $self->_get(@props, 'id'));
    } else {
        # It's a new record. Insert it!
        local $" = ', ';
        my $fields = join ', ', next_key('addr'), ('?') x $#props;
        my $ins = prepare_c(qq{
            INSERT INTO addr (@ins_cols)
            VALUES ($fields)
        }, undef);
        # Don't try to set ID - it will fail!
        execute($ins, $self->_get(@props[1..$#props]));
        # Now grab the ID.
        $self->_set({id => last_key('addr')});
    }
    return 1;
};

=item $success = &$save_parts($self, $parts)

Saves the address parts.

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

$save_parts = sub {
    my $self = shift;
    my $parts = shift;
    # Grab the queries.
    my ($ins, $upd, $del) = &$part_sql;

    # Grab the values we'll need.
    my ($vals, $pids, $aid) =
      $self->_get(qw(parts _part_ids id));

    foreach my $part (@$parts) {
        # Foreach part that has changed,
        if (defined $vals->{$part} & defined $pids->{$part}) {
            # If it's defined and has an ID. Update it.
            execute($upd, $aid, $vals->{$part}, $pids->{$part});
        } elsif (defined $vals->{$part}) {
            # It's defined but has no ID, so insert it.
            execute($ins, $aid, $part, $vals->{$part});
            $pids->{$part} = last_key('addr_part');
        } else {
            # If it's not defined, delete it.
            execute($del, $pids->{$part}) if $pids->{$part};
        }
    }
    $self->_set(['_part_ids'], [$pids]);
    return 1;
};

=item $success = &$save_lines($self)

Saves the address lines.

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

$save_lines = sub {
    my $self = shift;
    my ($lines, $aid) = $self->_get('_lines', 'id');

    # Grab the queries.
    my ($ins, $upd, $del) = &$part_sql;

    # Delete those that need deleting.
    foreach my $lid (@{ $lines->{_del} }) {
        execute($del, $lid);
    }
    delete $lines->{_del};

    # Update those that need updating.
    while (my ($lid, $val) = each %{ $lines }) {
        next if $lid eq '_add';
        execute($upd, $aid, $val, $lid);
    }

    # Insert those that need inserting.
    foreach my $val (@{ $lines->{_add} }) {
        execute($ins, $aid, 'Line', $val);
        $lines->{last_key('addr_part')} = $val;
    }
    delete $lines->{_add};
    return 1;
};

=item ($ins, $upd, $del) = &$part_sql

Prepares and returns SQL statements for inserting, updating, and deleting
address parts.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$part_sql = sub {
    # Prepare an insert query.
    local $" = ', ';
    my $ins = prepare_c(qq{
        INSERT INTO addr_part (id, addr__id,
                                         addr_part_type__id, value)
        VALUES (${ \next_key('addr_part') }, ?,
               (SELECT id
                FROM   addr_part_type
                WHERE  name = ?),
                ?)
    }, undef);

    # Prepare an update query.
    local $" = ' = ?, '; # Simple way to create placeholders.
    my $upd = prepare_c(qq{
        UPDATE addr_part
        SET    addr__id = ?,
               value = ?
        WHERE  id = ?
    }, undef);

    # Prepare a delete query.
    my $del = prepare_c(qq{
        DELETE FROM addr_part
        WHERE  id = ?
    }, undef);
    return ($ins, $upd, $del);
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
L<Bric::Biz::Org|Bric::Biz::Org>,
L<Bric::Biz::Person|Bric::Biz::Person>

=cut
