package Bric::Util::Grp::CategorySet;
###############################################################################

=head1 NAME

Bric::Util::Grp::CategorySet - A module to hold sets of categories.

=head1 VERSION

$Revision: 1.7 $

=cut

our $VERSION = (qw$Revision: 1.7 $ )[-1];

=head1 DATE

$Date: 2003-01-16 00:24:21 $

=head1 SYNOPSIS

 use Bric::Util::Grp::CategorySet;

 # Normal group methods.

=head1 DESCRIPTION

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

=head1 INTERFACE

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
    $class ||= Bric::Util::Class->lookup({ id => 47 });
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
    $mem_class ||= Bric::Util::Class->lookup({ id => 20 });
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
    return 47;
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

sub get_object_class_id { 20 }

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

################################################################################

=item my $secret = Bric::Util::Grp::Category->get_secret()

Returns false, because this is not a secret type of group, but one that can be
used by users.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_secret { 0 }

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

=head1 NOTES

NONE

=head1 AUTHOR

Garth Webb <garth@perijove.com>

=head1 SEE ALSO

L<perl>, L<Bric>, L<Bric::Util::Grp>

=cut
