package Bric::Util::Attribute::ElementType;

###############################################################################

=head1 Name

Bric::Util::Attribute::ElementType - Groups of Bric::Biz::ElementType objects.

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

This module is used internally only;

=head1 Description

The implimentations of asset type attributes.

=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies
use strict;

#--------------------------------------#
# Programatic Dependencies

#==============================================================================#
# Inheritance                          #
#======================================#

use base qw( Bric::Util::Attribute );

#=============================================================================#
# Function Prototypes                  #
#======================================#


#==============================================================================#
# Constants                            #
#======================================#


#==============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields

#--------------------------------------#
# Private Class Fields

#--------------------------------------#
# Instance Fields
# This method of Bricolage will call 'use fields' for you and set some permissions.
BEGIN {
    Bric::register_fields({});
}

#==============================================================================#

=head1 Interface

=head2 Constructors

ALL CONSTRUCTORS INHERITED

=head2 Public Class Methods

=over 4

=item $type = Bric::Util::Attribute::short_object_type();

Returns the short object type name used to construct the attribute table name
where the attributes for this class type are stored.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Values for this method look like 'grp' given a full object type of
Bric::Util::Grp.

=cut

sub short_object_type { return 'element_type' }

#--------------------------------------#

=back

=head2 Public Instance Methods

NONE

=cut

#==============================================================================#

=head1 Private

NONE

=cut

#--------------------------------------#

=head2 Private Class Methods

NONE

=cut

#--------------------------------------#

=head2 Private Instance Methods

NONE

=cut

#--------------------------------------#

=head2 Private Functions

NONE

=cut

1;
__END__

=head1 Notes

NONE

=head1 Author

Garth Webb <garth@perijove.com>

=head1 See Also

L<perl>, L<Bric>, L<Bric::Util::Attribute>, L<Bric::Biz::ElementType>

=cut
