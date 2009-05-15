package Bric::Util::Grp::CategorySet;

###############################################################################

=head1 Name

Bric::Util::Grp::CategorySet - A module to hold sets of categories.

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

 use Bric::Util::Grp::CategorySet;

 # Normal group methods.

=head1 Description

Allows assets to be grouped into categories. In addition to assets a category
can contain other categories, allowing a hierarchical layout of categories and
assets.

=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies
use strict;

#--------------------------------------#
# Programatic Dependencies
use Bric::Util::DBI qw(:standard);

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

use constant PACKAGE => 'Bric::Biz::CategorySet';
use constant CLASS_ID => 47;
use constant OBJECT_CLASS_ID => 20;

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

# This method of Bricolage will call 'use fields' for you and set some
# permissions.

BEGIN {
    Bric::register_fields({
             # Public Fields

             # Private Fields

            });
}

#==============================================================================#

=head1 Interface

=head2 Constructors

=over 4

=item $obj = new Bric::Util::Grp::CategorySet($init);

Inherited

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item @objs = lookup Bric::Util::Grp::CategorySet($cat_id);

Inherited

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

This is the default lookup constructor which should be overrided in all
derived classes even if it just calls 'die'.

=cut

#------------------------------------------------------------------------------#

=item @objs = list Bric::Util::Grp::CategorySet($param);

Inherited.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

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

=item my $class = Bric::Util::Grp::CategorySet->my_class()

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

=item my $class = Bric::Util::Grp::CategorySet->member_class()

Returns a Bric::Util::Class object describing the members of this group.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::Class->lookup() internally.

=cut

sub member_class {
    $mem_class ||= Bric::Util::Class->lookup({ id => OBJECT_CLASS_ID });
    return $mem_class;
}

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item $class_id = Bric::Util::Grp::CategorySet->get_class_id()

This will return the class id that this group is associated with it should
have an id that maps to the class object instance that is associated with the
class of the grp ie Bric::Util::Grp::AssetVersion

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

################################################################################

=item $class_id = Bric::Util::Grp::CategorySet->get_object_class_id()

Forces all Objects to be considered as this class.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_object_class_id { OBJECT_CLASS_ID }

#------------------------------------------------------------------------------#

=item my $h = $cat->get_supported_classes;

This supplies a package to table name mapping.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_supported_classes { { 'Bric::Biz::Category' => 'category' } }

##############################################################################

=item my @list_classes = Bric::Util::Grp::CategorySet->get_list_classes

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

sub get_list_classes { ('Bric::Biz::Category') }

################################################################################

=item my $secret = Bric::Util::Grp::Category->get_secret()

Returns false, because this is not a secret type of group, but one that can be
used by users.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_secret { Bric::Util::Grp::NONSECRET_GRP }

#==============================================================================#

=back

=head2 Private Methods

NONE

=head2 Private Class Methods

NONE

=head2 Private Instance Methods

NONE

=cut

1;
__END__

=head1 Notes

NONE

=head1 Author

Garth Webb <garth@perijove.com>

=head1 See Also

L<perl>, L<Bric>, L<Bric::Util::Grp>

=cut
