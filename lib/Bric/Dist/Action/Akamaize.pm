package Bric::Dist::Action::Akamaize;

=head1 Name

Bric::Dist::Action::Akamaize - Class to Akamaize resources

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  use Bric::Dist::Action::Akamaize;

  my $id = 2; # Assume that this is an akamaize action.
  # This line will automatically instantiate the correct subclass.
  my $action = Bric::Dist::Action->lookup({ id => $id });

  # Access its properties.
  my $dns_name = $action->get_dns_name;
  $action = $action->set_dns_name($dns_name);
  my $cp_code = $action->get_cp_code;
  $action = $action->set_cp_code($cp_code);
  my $seed_a = $action->get_seed_a;
  $action = $action->set_seed_a($seed_a);
  my $seed_b = $action->get_seed_b;
  $action = $action->set_seed_b($seed_b);

  # Perform the action on a list of resources.
  action = $action->do_it($resources_href);
  # Undo the action on a list of resources.
  action = $action->undo_it($resources_href);


=head1 Description

This subclass of Bric::Dist::Action handles the Akamiazation of resources. It
requires the properties DNS Name, CP Code, Seed A, and Seed B to do its job.
See the accessors below.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences

################################################################################
# Inheritance
################################################################################
use base qw(Bric::Dist::Action);

################################################################################
# Function and Closure Prototypes
################################################################################
my ($get_attr);

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
my ($meths, @ord);

################################################################################

################################################################################
# Instance Fields
BEGIN { Bric::register_fields(); }

################################################################################
# Class Methods
################################################################################

=head1 Interface

=head2 Constructors

Inherited from Bric::Dist::Action.

=head2 Destructors

=over 4

=item $ak->DESTROY

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

=item my $bool = Bric::Dist::Action::Akamaize->has_more()

Returns true to indicate that this action has more properties than does the base
class (Bric::Dist::Action).

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub has_more { return 1 }

################################################################################

=item $meths = Bric::Dist::Action::Akamaize->my_meths

=item (@meths || $meths_aref) = Bric::Dist::Action::Akamaize->my_meths(TRUE)

=item my (@meths || $meths_aref) = Bric::Dist::Action::Akamaize->my_meths(0, TRUE)

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
    my $ret = Bric::Dist::Action::Akamaize->SUPER::my_meths;

    foreach my $meth (Bric::Dist::Action::Akamaize->SUPER::my_meths(1)) {
    $meths->{$meth->{name}} = $meth;
    push @ord, $meth->{name};
    }

    push @ord, qw(dns_name cp_code seed_a seed_b), pop @ord;
    $meths->{dns_name} = {
              get_meth => sub { shift->get_dns_name(@_) },
              get_args => [],
              set_meth => sub { shift->set_dns_name(@_) },
              set_args => [],
              name     => 'dns_name',
              disp     => 'DNS Name',
              len      => 256,
              req      => 1,
              type     => 'short',
              props    => {   type      => 'text',
                      length    => 32,
                      maxlength => 256
                      }
             };
    $meths->{cp_code}  = {
              get_meth => sub { shift->get_cp_code(@_) },
              get_args => [],
              set_meth => sub { shift->set_cp_code(@_) },
              set_args => [],
              name     => 'cp_code',
              disp     => 'CP code',
              len      => 256,
              req      => 1,
              type     => 'short',
              props    => {   type      => 'text',
                      length    => 32,
                      maxlength => 256
                      }
             };
    $meths->{seed_a} = {
              get_meth => sub { shift->get_seed_a(@_) },
              get_args => [],
              set_meth => sub { shift->set_seed_a(@_) },
              set_args => [],
              name     => 'seed_a',
              disp     => 'Seed A',
              len      => 256,
              req      => 1,
              type     => 'short',
              props    => {   type      => 'text',
                      length    => 32,
                      maxlength => 256
                      }
             };
    $meths->{seed_b} = {
              get_meth => sub { shift->get_seed_b(@_) },
              get_args => [],
              set_meth => sub { shift->set_seed_b(@_) },
              set_args => [],
              name     => 'seed_b',
              disp     => 'Seed B',
              len      => 256,
              req      => 1,
              type     => 'short',
              props    => {   type      => 'text',
                      length    => 32,
                      maxlength => 256
                      }
             };

    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}];
}

################################################################################

=back

=head2 Public Instance Methods

In addition to the methods inherited from Bric::Dist::Action,
Bric::Dist::Action::Akamaize offers the following class methods:

=over 4

=item my $dns_name = $action->get_dns_name

Returns the DNS name required to akamaize files.

B<Throws:>

Thin accessor to attributes. The variables are defined as follows:

=over 4

=item *

$key - The name of the attribute to fetch or set.

=item *

$self - The Bric::Dist::Action::Akamaize object.

=item *

$value - The value to set the attribute to.

=item *

$set - A boolean - if true, sets the attribute to $value. If false, returns
the existing value of the attribute.

=back

B<Throws:>

=over 4

=item *

Problems retrieving fields.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=item *

Bad arguments.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=item *

Unable to select row.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_dns_name { &$get_attr( 'dns_name', @_) }

=item $self = $action->set_dns_name($dns_name)

Sets the DNS name required to akamaize files.

B<Throws:>

Thin accessor to attributes. The variables are defined as follows:

=over 4

=item *

$key - The name of the attribute to fetch or set.

=item *

$self - The Bric::Dist::Action::Akamaize object.

=item *

$value - The value to set the attribute to.

=item *

$set - A boolean - if true, sets the attribute to $value. If false, returns
the existing value of the attribute.

=back

B<Throws:>

=over 4

=item *

Problems retrieving fields.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=item *

Bad arguments.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=item *

Unable to select row.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_dns_name { &$get_attr( 'dns_name', @_[0..1], 1 ) }

=item my $cp_code = $action->get_cp_code

Returns the CP Code required to akamaize files.

B<Throws:>

Thin accessor to attributes. The variables are defined as follows:

=over 4

=item *

$key - The name of the attribute to fetch or set.

=item *

$self - The Bric::Dist::Action::Akamaize object.

=item *

$value - The value to set the attribute to.

=item *

$set - A boolean - if true, sets the attribute to $value. If false, returns
the existing value of the attribute.

=back

B<Throws:>

=over 4

=item *

Problems retrieving fields.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=item *

Bad arguments.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=item *

Unable to select row.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_cp_code { &$get_attr( 'cp_code', @_) }

=item $self = $action->set_cp_code($cp_code)

Sets the CP Code required to akamaize files.

B<Throws:>

Thin accessor to attributes. The variables are defined as follows:

=over 4

=item *

$key - The name of the attribute to fetch or set.

=item *

$self - The Bric::Dist::Action::Akamaize object.

=item *

$value - The value to set the attribute to.

=item *

$set - A boolean - if true, sets the attribute to $value. If false, returns
the existing value of the attribute.

=back

B<Throws:>

=over 4

=item *

Problems retrieving fields.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=item *

Bad arguments.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=item *

Unable to select row.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_cp_code { &$get_attr( 'cp_code', @_[0..1], 1 ) }

=item my $seed_a = $action->get_seed_a

Returns seed A, which is required to akamaize files.

B<Throws:>

Thin accessor to attributes. The variables are defined as follows:

=over 4

=item *

$key - The name of the attribute to fetch or set.

=item *

$self - The Bric::Dist::Action::Akamaize object.

=item *

$value - The value to set the attribute to.

=item *

$set - A boolean - if true, sets the attribute to $value. If false, returns
the existing value of the attribute.

=back

B<Throws:>

=over 4

=item *

Problems retrieving fields.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=item *

Bad arguments.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=item *

Unable to select row.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_seed_a { &$get_attr( 'seed_a', @_) }

=item $self = $action->set_seed_a($seed_a)

Sets seed A, which is required to akamaize files.

B<Throws:>

Thin accessor to attributes. The variables are defined as follows:

=over 4

=item *

$key - The name of the attribute to fetch or set.

=item *

$self - The Bric::Dist::Action::Akamaize object.

=item *

$value - The value to set the attribute to.

=item *

$set - A boolean - if true, sets the attribute to $value. If false, returns
the existing value of the attribute.

=back

B<Throws:>

=over 4

=item *

Problems retrieving fields.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=item *

Bad arguments.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=item *

Unable to select row.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_seed_a { &$get_attr( 'seed_a', @_[0..1], 1 ) }

=item my $seed_b = $action->get_seed_b

Returns seed B, which is required to akamaize files.

B<Throws:>

Thin accessor to attributes. The variables are defined as follows:

=over 4

=item *

$key - The name of the attribute to fetch or set.

=item *

$self - The Bric::Dist::Action::Akamaize object.

=item *

$value - The value to set the attribute to.

=item *

$set - A boolean - if true, sets the attribute to $value. If false, returns
the existing value of the attribute.

=back

B<Throws:>

=over 4

=item *

Problems retrieving fields.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=item *

Bad arguments.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=item *

Unable to select row.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_seed_b { &$get_attr( 'seed_b', @_) }

=item $self = $action->set_seed_b($seed_b)

Sets seed B, which is required to akamaize files.

B<Throws:>

Thin accessor to attributes. The variables are defined as follows:

=over 4

=item *

$key - The name of the attribute to fetch or set.

=item *

$self - The Bric::Dist::Action::Akamaize object.

=item *

$value - The value to set the attribute to.

=item *

$set - A boolean - if true, sets the attribute to $value. If false, returns
the existing value of the attribute.

=back

B<Throws:>

=over 4

=item *

Problems retrieving fields.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=item *

Bad arguments.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=item *

Unable to select row.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_seed_b { &$get_attr( 'seed_b', @_[0..1], 1 ) }

################################################################################

=item $self = $action->do_it($job, $server_type)

Akamaizes the files for a given job and server type.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub do_it {
    # Perform the akamaization.
    my ($self, $resources) = @_;
    my $types = $self->get_media_href;
    foreach my $res (@$resources) {
    next unless $types->{$res->get_media_type};
    my $path = $res->get_tmp_path || $res->get_path;
    print STDERR "Akamaize $path here.\n";
    }
    print STDERR "\n";
}

################################################################################

=back

=head1 Private

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

=over 4

=item $action = $action->_clear_attr

Deletes all attributes from this Bric::Dist::Action::Akamaize instnace. Called by
Bric::Dist::Action::set_type() above so that all the attributes can be cleared
before reblessing the action into a different action subclass.

B<Throws:>

=over 4

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

sub _clear_attr {
    my $self = shift;
    my $attr = $self->_get_attr;
    $attr->delete_attr({ name => $_, subsys => 'Akamaize' })
      for qw(dns_name ce_code seed_a seed_b);
    return $self;
}

=back

=head2 Private Functions

=over 4

=item my $value = &$get_attr($key, $self, $value, $set)

Thin accessor to attributes. The variables are defined as follows:

=over 4

=item *

$key - The name of the attribute to fetch or set.

=item *

$self - The Bric::Dist::Action::Akamaize object.

=item *

$value - The value to set the attribute to.

=item *

$set - A boolean - if true, sets the attribute to $value. If false, returns
the existing value of the attribute.

=back

B<Throws:>

=over 4

=item *

Problems retrieving fields.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=item *

Bad arguments.

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to execute SQL statement.

=item *

Unable to select row.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$get_attr = sub {
    my ($key, $self, $value, $set) = @_;
    my $attr = $self->_get_attr;
    if ($set) {
    $attr->set_attr({ name => $key, subsys => 'Akamaize',
              sql_type => 'short', value => $value });
    } else {
    $attr->get_attr({ name => $key, subsys => 'Akamaize' });
    }
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
L<Bric::Dist::Action|Bric::Dist::Action>

=cut
