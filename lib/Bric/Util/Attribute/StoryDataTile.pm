package Bric::Util::Attribute::StoryDataTile;

=head1 NAME

Bric::Util::Attribute::Story - Interface to Attributes of Bric::Biz::Story objects

=head1 VERSION

$Revision: 1.1.1.1.2.2 $

=cut

# Grab the Version Number.
our $VERSION = (qw$Revision: 1.1.1.1.2.2 $ )[-1];

=head1 DATE

$Date: 2001-11-06 23:18:35 $

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

sub short_object_type { 'story_data_tile' }

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

perl(1),
Bric (2),
Bric::Util::Attribute(4)

=cut

