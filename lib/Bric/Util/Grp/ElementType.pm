package Bric::Util::Grp::ElementType;

=head1 Name

Bric::Util::Grp::ElementType - Interface to Element Groups

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

See Bric::Util::Grp

=head1 Description

See Bric::Util::Grp.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;
use Bric::Util::Grp;

################################################################################
# Programmatic Dependences

################################################################################
# Inheritance
################################################################################
use base qw(Bric::Util::Grp::SubelementType);

################################################################################
# Function Prototypes
################################################################################


################################################################################
# Constants
################################################################################
use constant DEBUG    => 0;
use constant CLASS_ID => 70;

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields
my ($class);

################################################################################

################################################################################
# Instance Fields
BEGIN { Bric::register_fields() }

################################################################################
# Class Methods
################################################################################

=head1 Interface

=head2 Constructors

Inherited from Bric::Util::Grp.

=head2 Destructors

=over 4

=item $attr->DESTROY

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

=item $class_id = Bric::Util::Grp::ElementType->get_class_id()

This will return the class ID that this group is associated with.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_class_id { CLASS_ID }

################################################################################

=item my $secret = Bric::Util::Grp::ElementType->get_secret()

Returns false, because this is not a secret type of group, but one that can be
used by users.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_secret { Bric::Util::Grp::NONSECRET_GRP }

################################################################################

=item my $class = Bric::Util::Grp::ElementType->my_class()

Returns a Bric::Util::Class object describing this class.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::Class->lookup() internally.

=cut

sub my_class {
    $class ||= Bric::Util::Class->lookup({ id => CLASS_ID });
    return $class;
}

################################################################################

=back

=head2 Public Instance Methods

Inherited from Bric::Util::Grp.

=head1 Private

=head2 Private Constructors

NONE.

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

NONE.

=cut

1;
__END__

=head1 Notes

NONE.

=head1 Author

David Wheeler <david@justatheory.com>

=head1 See Also

L<Bric|Bric>,
L<Bric::Biz::ElementType|Bric::Biz::ElementType>,
L<Bric::Util::Grp|Bric::Util::Grp>

=cut
