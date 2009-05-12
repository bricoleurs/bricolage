package Bric::Util::Grp::SubelementType;

###############################################################################

=head1 Name

Bric::Util::Grp::SubelementType - A group of ElementTypes.

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

 use Bric::Util::Grp::SubelementType;


=head1 Description

This is for holding groups of ElementTypes.

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
use base qw( Bric::Util::Grp );

#=============================================================================#
# Function Prototypes                  #
#======================================#


#==============================================================================#
# Constants                            #
#======================================#

use constant PACKAGE         => 'Bric::Biz::ElementType';
use constant TABLE           => 'element_type';
use constant CLASS_ID        => 24;
use constant OBJECT_CLASS_ID => 22;

#==============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields

#--------------------------------------#
# Private Class Fields
my ($class, $mem_class);


#--------------------------------------#
# Instance Fields

# This method of Bricolage will call 'use fields' for you and set some permissions.
BEGIN {
    Bric::register_fields({
    });
}

#==============================================================================#

=head1 Interface

=head2 Constructors

=over 4

=item $obj = new Bric::Util::Grp::SubelementType->new($init);

Creates a new assettype group.  Uses inherited 'new' method.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item @objs = lookup Bric::Util::Grp::SubelementType->lookup($param);

Uses inherited 'lookup' method.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item @objs = list Bric::Util::Grp::SubelementType->list($param);

Uses inherited 'list' method.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

##############################################################################

=back

=head2 Destructors

=over 4

=item $self->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY

=cut

sub DESTROY {
    # This method should be here even if its empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

##############################################################################

=back

=head2 Public Class Methods

=over 4

=item $class_id = Bric::Util::Grp::Category->get_class_id()

This will return the class id that this group is associated with
it should have an id that maps to the class object instance that is
associated with the class of the grp ie Bric::Util::Grp::AssetVersion

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>

Overwite this in your sub classes

=cut

sub get_class_id {
    return CLASS_ID;
}

#------------------------------------------------------------------------------#

=item $h = $key->get_supported_classes;

This supplies a package to table name mapping.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_supported_classes {
    return {
       &PACKAGE => TABLE,
       'Bric::Biz::ElementType::Subelement' => TABLE,
    };
}

##############################################################################

=item my @list_classes = Bric::Util::Grp::SubelementType->get_list_classes

Returns a list or anonymous array of the supported classes in the group that
can have their C<list()> methods called in succession to assemble a list of
member objects. This data varies from that stored in the keys in the hash
reference returned by C<get_supported_classes> in that some classes' C<list()>
methods may inherit from others, and we don't want the same C<list()> method
executed more than once.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_list_classes { (PACKAGE) }

################################################################################

=item $class_id = Bric::Util::Grp::SubelementType->get_object_class_id

Forces all Objects to be considered as this class.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_object_class_id { OBJECT_CLASS_ID }

################################################################################

=item my $class = Bric::Util::Grp::SubelementType->my_class()

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

=item my $class = Bric::Util::Grp::SubelementType->member_class()

Returns a Bric::Util::Class object describing the members of this group.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::Class->lookup() internally.

=cut

sub member_class {
    $mem_class ||= Bric::Util::Class->lookup({ id => OBJECT_CLASS_ID });
    return $mem_class;
}

##############################################################################

=back

=head2 Public Instance Methods

NONE.

=head2 Private Methods

NONE.

=head2 Private Class Methods

NONE


=head2 Private Instance Methods

NONE

=cut

1;
__END__

=head1 Author

"Garth Webb" <garth@perijove.com> Bricolage Engineering

=head1 See Also

L<perl>, L<Bric>, L<Bric::Biz::ElementType>

=cut
