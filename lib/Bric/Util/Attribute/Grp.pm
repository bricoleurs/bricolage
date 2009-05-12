package Bric::Util::Attribute::Grp;

=head1 Name

Bric::Util::Attribute::Grp - Interface to Attributes of Bric::Util::Grp objects

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

See Bric::Util::Attribute

=head1 Description

Bric::Util::Attribute::Grp currently inherits all methods from
Bric::Util::Attribute. It may be extended later.

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
    Bric::register_fields();
}

################################################################################
# Class Methods
################################################################################

=head1 Interface

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

Returns the short object type name used to construct the attribute table name
where the attributes for this class type are stored.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Values for this method look like 'grp' given a full object type of
'Bric::Util::Grp'.

=cut

sub short_object_type { return 'grp' }

################################################################################

=item $type = Bric::Util::Attribute::instance_class();

Returns the instance class name which may just be the instance class itself, or
a subclass of it.  Used to determine what type of attribute instance object
should be returned.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Values for this method look like 'grp' given a full object type of
'Bric::Util::Grp'.

=cut

sub instance_class { return 'Bric::Util::Attribute::Parts::Instance' }

################################################################################

=item $type = Bric::Util::Attribute::full_object_type();

Returns the full object type to which this attribute object applies.  Any object
can have attributes.

B<Throws:> NONE.

B<Side Effects:> NONE

B<Notes:> Values for this method look like 'Bric::Util::Grp'.

=cut

sub full_object_type { return 'Bric::Util::Grp' }

################################################################################

=back

=head2 Public Instance Methods

Inherited from Bric::Util::Attribute.

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

This is an early draft of this class, and therefore subject to change.

=head1 Author

David Wheeler <david@justatheory.com>

=head1 See Also

L<Bric|Bric>, 
L<Bric::Util::Grp|Bric::Util::Grp>, 
L<Bric::Util::Attribute|Bric::Util::Attribute>

=cut

