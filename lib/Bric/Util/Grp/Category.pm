package Bric::Util::Grp::Category;
###############################################################################

=head1 NAME

  Bric::Util::Grp::Category - A module to group assets into categories.

=head1 VERSION

$Revision: 1.1.1.1.2.2 $

=cut

our $VERSION = (qw$Revision: 1.1.1.1.2.2 $ )[-1];

=head1 DATE

$Date: 2001-11-06 23:18:36 $

=head1 SYNOPSIS

 use Bric::Util::Grp::Category;

 # Return a new category object.
 my $cat = new Bric::Util::Grp::Category($init);

 my $cat = lookup Bric::Util::Grp::Category({'id' => $cat_id});

 my @cat = list Bric::Util::Grp::Category($param);

 # Get/set the name of this category.
 $cat    = $cat->set_name($name);
 $name   = $cat->get_name()

 # Get/set the description of this category.
 $cat    = $cat->set_description()
 $desc   = $cat->get_description()

 # Get the parent of this category.
 $parent  = $cat->get_parent();

 # Add one or more sub categories to this category.
 $success = $cat->add_subcat(@cat_id || @cat_obj);

 # Return all sub categories of this category.
 @cats    = $cat->all_subcat();

 # Save this category to the database.
 $success = $cat->save();

 # Remove this category from the database.
 $success = $cat->remove();

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

use constant PACKAGE => 'Bric::Biz::Category';

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

=item $obj = new Bric::Util::Grp::Category($init);

Inherited

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#------------------------------------------------------------------------------#

=item @objs = lookup Bric::Util::Grp::Category($cat_id);

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

=item @objs = list Bric::Util::Grp::Category($param);

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
    return 23;
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
#    { 
#	&PACKAGE => 'keyword',
#    }

	{ 'Bric::Biz::Category' => 'category' }
}	

#------------------------------------------------------------------------------#

################################################################################

=item my $secret = Bric::Util::Grp::Category->get_secret()

Returns true, because this is a secret type of group, can' be directly used by
users.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_secret { 1 }

################################################################################

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
    my Bric::Util::Grp::Category $self = shift;
    my $p_id = $self->get_parent_id;
    
    if ($p_id) {
	my @c = Bric::Biz::Category->list({'category_grp_id' => $p_id,
					'active'          => 'all'});
	return $c[0];
    } else {
	return;
    }
}

#------------------------------------------------------------------------------#

=item $success = $cat->add_subcat([@cat_id || @cat_obj]);

Add one or more sub categories to this category.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub add_subcat {
    my Bric::Util::Grp::Category $self = shift;
    my ($cat) = @_;
    my $pkg = 'Bric::Biz::Category';

    foreach my $c (@$cat) {
	my $c_cat = $c->_get('_category_grp_obj');
	$c_cat->set_parent_id($self->get_id);
	$c_cat->save;
    }

    # The $cat array can almost be passed directoy to add_members that a list
    # of IDs needs to be transformed into a hash ref of ID *and* type.
    $self->add_members([map {ref($_) ? {'obj'=>$_} 
			             : {'type'=>PACKAGE, 'id'=>$_}} @$cat]);
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

sub all_subcat {
    my Bric::Util::Grp::Category $self = shift;

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
    my Bric::Util::Grp::Category $self = shift;

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

sub _select_by_name {
    my ($name, $active) = @_;
    my (@ret, @d);
    my $sql;

    $sql = 'SELECT c.id, c.directory, c.asset_grp_id, c.category_grp_id, c.keyword_grp_id '.
           'FROM   grp g, category c '.
	   'WHERE  LOWER(g.name) LIKE ? AND g.id = c.category_grp_id '.
                   'AND c.active = ?';

    my $sth = prepare_c($sql);
    execute($sth, lc($name), $active);
    bind_columns($sth, \@d[0..4]);
    while (fetch($sth)) {
	push @ret, [@d];
    }
    finish($sth);

    return \@ret;
}

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
