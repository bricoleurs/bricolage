package Bric::Util::Attribute::Formatting;

=head1 NAME

Bric::Util::Attribute::Story - Interface to Attributes of 
Bric::Biz::Asset::Formatting objects

=head1 VERSION

$Revision: 1.6 $

=cut

# Grab the Version Number.
use Bric; our $VERSION = Bric->VERSION;

=head1 DATE

$Date: 2002/01/06 04:40:36 $

=head1 SYNOPSIS

See Bric::Util::Attribute

=head1 DESCRIPTION

See Bric::Util::Attribute.

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
use base qw(Bric::Util::Attribute);

################################################################################
# Function Prototypes
################################################################################


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

################################################################################

################################################################################
# Instance Fields
BEGIN {
    Bric::register_fields({});
}

################################################################################
# Class Methods
################################################################################

=head1 INTERFACE

=head2 Constructors

Inherited from Bric::Util::Attribute.

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

=over 4

=item $type = Bric::Util::Attribute::short_object_type();

Returns 'person', the short object type name used to construct the attribute
table name where the attributes for this class type are stored.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub short_object_type { 'formatting' }

################################################################################

=back

=head2 Public Instance Methods

Inherited from Bric::Util::Attribute.

=head1 PRIVATE

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

=head1 NOTES

NONE.

=head1 AUTHOR

Michael Soderstrom <miraso@pacbell.net>

=head1 SEE ALSO

L<Bric|Bric>, 
L<Bric::Util::Attribute|Bric::Util::Attribute>

=cut

