package Bric::Util::Grp::BA;
###############################################################################

=head1 NAME

  Bric::Util::Grp::Category - A module to group assets into categories.

=head1 VERSION

$Revision: 1.4 $

=cut

our $VERSION = (qw$Revision: 1.4 $ )[-1];

=head1 DATE

$Date: 2001-11-20 00:02:46 $

=head1 SYNOPSIS

 use Bric::Util::Grp::BA;

 # Return a new category object.
 my $bag = new Bric::Util::Grp::BA($init);

 my $bag = lookup Bric::Util::Grp::BA({'id' => $cat_id});

 my @bag = list Bric::Util::Grp::BA($param);

 # Get/set the name of this category.
 $bag    = $bag->set_name($name);
 $name   = $bag->get_name()

 # Get/set the description of this category.
 $bag    = $bag->set_description()
 $desc   = $bag->get_description()

 # Get the parent of this category.
 $parent  = $bag->get_parent();

 # Add one or more sub categories to this category.
 $bag     = $bag->add_asset([@ba_obj]);
 $bag     = $bag->add_media_id([$id]);
 $bag     = $bag->add_story_id([$id]);

 # Return all sub bagegories of this bagegory.
 @bags    = $bag->get_assets();

 # Save this category to the database.
 $success = $bag->save();

 # Remove this category from the database.
 $success = $bag->remove();

=head1 DESCRIPTION

Allows assets to be grouped into categories.  In addition to assets a category 
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

use constant STORY_PKG => 'Bric::Biz::Asset::Business::Story';
use constant MEDIA_PKG => 'Bric::Biz::Asset::Business::Media';

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

=item $obj = new Bric::Util::Grp::BA($init);

Inherited

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item @objs = lookup Bric::Util::Grp::BA($cat_id);

Inherited

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

This is the default lookup constructor which should be overrided in all derived 
classes even if it just calls 'die'.

=cut

#------------------------------------------------------------------------------#

=item @objs = list Bric::Util::Grp::BA($param);

Inherited.

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

NONE

=cut

# Add methods here that do not require an object be instantiated to call them.
# Use same POD comment style as above for 'new'.

#--------------------------------------#

=head2 Public Instance Methods

=cut

#------------------------------------------------------------------------------#

=item $class_id = Bric::Util::Grp::BA->get_class_id()

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
    return 1047;
}

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

sub get_supported_classes {
    return { &STORY_PKG => 'story',
	     &MEDIA_PKG => 'media'}
}	

#------------------------------------------------------------------------------#

=item $parent = $cat->parent();

Get/set the parent of this category.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_parent {
    my Bric::Util::Grp::BA $self = shift;
    my $p_id = $self->get_parent_id;
    
    if ($p_id) {
	return Bric::Biz::BA->lookup($p_id);
    } else {
	return;
    }
}

#------------------------------------------------------------------------------#

=item $success = $cat->add_asset([$asset_obj]);

Add one or more sub categories to this category.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub add_asset {
    my Bric::Util::Grp::BA $self = shift;
    my ($asset) = @_;

    $self->add_members([map {{'obj'=>$_}} @$asset]);
}

#------------------------------------------------------------------------------#

=item $success = $cat->add_story_id([$story_id]);

Add a story asset ID.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub add_story_id {
    my Bric::Util::Grp::BA $self = shift;
    my ($s_id) = @_;

    $self->add_members([map {{'id'=>$_,'type'=>STORY_PKG}} @$s_id]);
}

#------------------------------------------------------------------------------#

=item $success = $cat->add_media_id([$media_id]);

Add a media asset ID.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub add_media_id {
    my Bric::Util::Grp::BA $self = shift;
    my ($m_id) = @_;

    $self->add_members([map {{'id'=>$_,'type'=>MEDIA_PKG}} @$m_id]);
}

#------------------------------------------------------------------------------#

=item @cats = $cat->all_subcat();

Return all sub categories of this category.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_assets {
    my Bric::Util::Grp::BA $self = shift;

    # Simply a pass-through.
    return map {$_->get_object} $self->get_members;
}

#------------------------------------------------------------------------------#

=item $success = $cat->remove();

Remove this category from the database.

B<Throws:>

=over 4

=item *

"Method not implemented"

=back

B<Side Effects:>

NONE

B<Notes:>

This call will remove itself and all its associations with keywords, other 
categories and assets.  This will *not* delete the objects attached to these
associations.

=cut

sub remove {
    my Bric::Util::Grp::BA $self = shift;

    # Implement when a remove method is added to the parent.

    # HACK: This should throw an error object.
    die __PACKAGE__.":remove - Method not implemented\n";
}

#==============================================================================#

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

NONE

=head1 AUTHOR

"Garth Webb" <garth@perijove.com>
Bricolage Engineering

=head1 SEE ALSO

L<perl>, L<Bric>, L<Bric::Util::Grp>

=cut
