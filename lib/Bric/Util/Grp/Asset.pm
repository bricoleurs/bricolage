package Bric::Util::Grp::Asset;

###############################################################################

=head1 Name

Bric::Util::Grp::Category - A module to group assets into categories.

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

 use Bric::Util::Grp::Asset;

 # Return a new category object.
 my $bag = new Bric::Util::Grp::Asset($init);

 my $bag = lookup Bric::Util::Grp::Asset({'id' => $cat_id});

 my @bag = list Bric::Util::Grp::Asset($param);

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

=head1 Description

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
use Bric::Util::Fault qw(throw_mni);


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

use constant STORY_PKG  => 'Bric::Biz::Asset::Business::Story';
use constant MEDIA_PKG  => 'Bric::Biz::Asset::Business::Media';
use constant FORMAT_PKG => 'Bric::Biz::Asset::Template';
use constant AUDIO_PKG => 'Bric::Biz::Asset::Business::Media::Audio';
use constant IMAGE_PKG => 'Bric::Biz::Asset::Business::Media::Image';
use constant VIDEO_PKG => 'Bric::Biz::Asset::Business::Media::Video';
use constant CLASS_ID => 43;
use constant OBJECT_CLASS_ID => 69;

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

=head1 Interface

=head2 Constructors

=over 4

=cut

#--------------------------------------#
# Constructors                          

#------------------------------------------------------------------------------#

=item $obj = new Bric::Util::Grp::Asset($init);

Inherited

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item @objs = lookup Bric::Util::Grp::Asset($cat_id);

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

=item @objs = list Bric::Util::Grp::Asset($param);

Inherited.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#--------------------------------------#

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

NONE

=cut

# Add methods here that do not require an object be instantiated to call them.
# Use same POD comment style as above for 'new'.

#--------------------------------------#

=head2 Public Instance Methods

=over 4

=item $class_id = Bric::Util::Grp::Asset->get_class_id()

This will return the class id that this group is associated with
it should have an id that maps to the class object instance that is
associated with the class of the grp ie Bric::Util::Grp::AssetVersion

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

Overwrite this in your sub classes

=cut

sub get_class_id { CLASS_ID }

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
    return { &STORY_PKG  => 'story',
         &MEDIA_PKG  => 'media',
         &FORMAT_PKG => 'template',
         &AUDIO_PKG  => 'media',
         &IMAGE_PKG  => 'media',
         &VIDEO_PKG  => 'media'
       }
}

##############################################################################

=item my @list_classes = Bric::Util::Grp::Asset->get_list_classes

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

sub get_list_classes { ( STORY_PKG, MEDIA_PKG, FORMAT_PKG) }

################################################################################

=item my $class = Bric::Util::Grp::Asset->my_class()

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

=item my $class = Bric::Util::Grp::Asset->member_class()

Returns a Bric::Util::Class object describing the members of this group.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Uses Bric::Util::Class->lookup() internally.

=cut

sub member_class {
    $mem_class ||= Bric::Util::Class->lookup({ id => OBJECT_CLASS_ID });
    return $mem_class;
}

#------------------------------------------------------------------------------#

=item $success = $grp->add_asset([$asset_obj]);

Add one or more sub categories to this category.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub add_asset {
    my ($self, $asset) = @_;
    $self->add_members([ map { { obj => $_ } } @$asset ]) if @$asset;
    return $self;
}

#------------------------------------------------------------------------------#

=item $success = $cat->grp_story_id([$story_id]);

Add a story asset ID.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub add_story_id {
    my $self = shift;
    my ($s_id) = @_;

    $self->add_members([map {{'id'=>$_,'type'=>STORY_PKG}} @$s_id]);
}

#------------------------------------------------------------------------------#

=item $success = $grp->add_media_id([$media_id]);

Add a media asset ID.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub add_media_id {
    my $self = shift;
    my ($m_id) = @_;

    $self->add_members([map {{'id'=>$_,'type'=>MEDIA_PKG}} @$m_id]);
}

#------------------------------------------------------------------------------#

=item $success = $grp->add_template_id([$media_id]);

Add a template ID.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub add_template_id {
    my $self = shift;
    my ($t_id) = @_;

    $self->add_members([map {{'id'=>$_,'type'=>FORMAT_PKG}} @$t_id]);
}

#------------------------------------------------------------------------------#

=item @assets = $grp->get_assets

Return all assets.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_assets {
    my $self = shift;

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
    my $self = shift;

    # Implement when a remove method is added to the parent.

    throw_mni(error => 'Method not implemented');
}

#==============================================================================#

=back

=head2 Private Methods

=cut

#--------------------------------------#

=head2 Private Class Methods

NONE

=cut

#--------------------------------------#

=head2 Private Instance Methods

NONE

=cut

1;
__END__

=head1 Notes

NONE

=head1 Author

"Garth Webb" <garth@perijove.com>
Bricolage Engineering

=head1 See Also

L<perl>, L<Bric>, L<Bric::Util::Grp>

=cut

