package Bric::Util::Grp::AssetType;
###############################################################################

=head1 NAME

Bric::Util::Grp::AssetType - A group of AssetTypes.

=head1 VERSION

$Revision: 1.2 $

=cut

our $VERSION = substr(q$Revision: 1.2 $, 10, -1);

=head1 DATE

$Date: 2001-10-09 20:48:55 $

=head1 SYNOPSIS

 use Bric::Util::Grp::AssetType;


=head1 DESCRIPTION

This is for holding groups of AssetTypes.

=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies                 

use strict;

#--------------------------------------#
# Programatic Dependencies              
 
use Bric::Util::Grp::Keyword;

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

use constant PACKAGE      => 'Bric::Biz::AssetType';
use constant TABLE        => 'element';
use constant GRP_CLASS_ID => 24;

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
			 # Public Fields

			 # Private Fields
			 
			});
}

#==============================================================================#

=head1 INTERFACE

=head2 Constructors

=over 4

=cut

#--------------------------------------#
# Constructors                          

#------------------------------------------------------------------------------#

=item $obj = new Bric::Util::Grp::Keyword($init);

Creates a new keyword synonym group.  Uses inherited 'new' method.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item @objs = lookup Bric::Util::Grp::Keyword($param);

Uses inherited 'lookup' method.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item @objs = list Bric::Util::Grp::Keyword($param);

Uses inherited 'list' method.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#--------------------------------------#

=head2 Destructors

=cut

sub DESTROY {
    # This method should be here even if its empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

#--------------------------------------#

=head2 Public Class Methods

=cut

#--------------------------------------#

=head2 Public Instance Methods

=cut

#------------------------------------------------------------------------------#

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
    return GRP_CLASS_ID;
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
    return { &PACKAGE => TABLE };
}	

#==============================================================================#

################################################################################

=item my $class = Bric::Util::Grp::AssetType->my_class()

Returns a Bric::Util::Class object describing this class.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::Class->lookup() internally.

=cut

sub my_class {
    $class ||= Bric::Util::Class->lookup({ id => GRP_CLASS_ID });
    return $class;
}

################################################################################

=item my $class = Bric::Util::Grp::AssetType->member_class()

Returns a Bric::Util::Class object describing the members of this group.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::Class->lookup() internally.

=cut

sub member_class {
    $mem_class ||= Bric::Util::Class->lookup({ id => 22 });
    return $mem_class;
}

=head2 Private Methods

=cut

#--------------------------------------#

=head2 Private Class Methods

NONE

=cut


# Add methods here that do not require an object be instantiated, and should not
# be called outside this module (e.g. utility functions for class methods).
# Use same POD comment style as above for 'new'.

#--------------------------------------#

=head2 Private Instance Methods

NONE

=cut

# Add methods here that apply to an instantiated object, but should not be 
# called directly (e.g. utility functions for instance methods).
# Use same POD comment style as above for 'new'.

1;
__END__

=back

=head1 NOTES

This module is the group implimentation of keyword synonyms.  All functionality
needed for keyword synonyms is implimented here and used by Bric::Biz::Keyword which 
represents the front end interface.

=head1 AUTHOR

"Garth Webb" <garth@perijove.com>
Bricolage Engineering

=head1 SEE ALSO

L<perl>, L<Bric>, L<Bric::Biz::Keyword>

=cut
