package Bric::Group;
###############################################################################

=head1 NAME

 Bric::Group - A Class for associating Objects 


=head1 VERSION

$Revision: 1.4 $

=cut

our $VERSION = (qw$Revision: 1.4 $ )[-1];


=head1 DATE

$Date: 2001-11-20 00:02:44 $


=head1 SYNOPSIS

 $group = Bric::Group->new();

 $group = $group->set_name( $name )

 $name = $group->get_name()

 $group = $group->set_description()

 $desc = $group->get_description()

 $id = $group->get_id()

 $success = $group->delete() || $success = Bric::Group->delete( $group_id )

 ($member || undef) = Bric::Group->is_associated( 
	($obj || {type => $t, id => $id} ), $group_id ,$attr )

 $group = $group->set_members( [$obj || { type => $type, id => $id}] )

 (@members || $member_aref) = $group->get_members()

 $group = $group->delete_members([$obj || $member || {type=> $t,id=> $id}])

 ($member || undef) = $group->has_member( 
	($obj || {type => $t, id => $id}, $attr )

 $attr_obj = $group->get_attr_obj()

 (@vals || $val_aref) = 
	$group->get_member_attrs( [ { name => $name, subsys => $subsys} ])

 $success = $group->set_member_attrs(
	[ { name => $name, subsys => $subsys, value => $value } ] )


 (@vals || $val_aref) =
	$group->get_group_attrs( [ $name ])

 $success = $group->set_group_attrs(
 	[ { name => $name, value => $value } ] )

 $group = $group->save()

=head1 DESCRIPTION

 Group is a class that associates Objects together.   These can be
 assigned Attributes as a group or to the member class which will 
 allow attributes to be set on an object in association with a group.

 

=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies                 

use strict;

#--------------------------------------#
# Programatic Dependencies              

# None Yet

#==============================================================================#
# Inheritance                          #
#======================================#

# The parent module should have a 'use' line if you need to import from it.
# use Bric;
use base qw(Bric);

#=============================================================================#
# Function Prototypes                  #
#======================================#

# None

#==============================================================================#
# Constants                            #
#======================================#

# None

#==============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields                   

# Public fields should use 'vars'
#use vars qw();

#--------------------------------------#
# Private Class Fields                  

# Private fields use 'my'

#--------------------------------------#
# Instance Fields                       

# None

# This method of Bricolage will call 'use fields' for you and set some permissions.
BEGIN {
    Bric::register_fields({
			# Public Fields

			# The Name of the group
			'name'			=> Bric::FIELD_RDWR,

			# description
			'description'	=> Bric::FIELD_RDRW,

			# Private Fields

			# A List of Member Objects			
			'_members'		=> Bric::FIELD_NONE	

	});
}

#==============================================================================#
# Interface Methods                    #
#======================================#

=head1 INTERFACE

=head2 Public Methods

=over 4

=cut

#--------------------------------------#
# Constructors                          

#------------------------------------------------------------------------------#

=item $group = Bric::Group->new()

 This will create a new group object

B<notes:>

B<throws:>
 None

B<side effects:>
 None

B<notes:>
 None

=cut

sub new {

}

=item $group = Bric::Group->lookup( $criteria )

 This will lookup an existing group based on the given criteria, usualy 
 $criteria = { id => $id }

B<throws:>
 None

B<side effects:>
 None

B<notes:>
 None

=cut

sub lookup {

}

=item (@groups || $group_aref) = Bric::Group->list( $criteria )

 Given the hash ref of args (what they might be will be defined in a bit)
 this will return a list or a list ref of objects that match.

B<throws:>
 None

B<side effects:>
 None

B<notes:>
 None

=cut

sub list {

}

#--------------------------------------#
# Destructors                           

sub DESTROY {
    # This method should be here even if its empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

#--------------------------------------#
# Public Class Methods                  

=item $success = Bric::Group->delete( [$group] );

 This will remove the group(s) that are passed as args

B<throws:>
 None

B<side effects:>
 None

B<notes:>
 None

=cut

sub delete {

}

=item ($member || undef) = Bric::Group->is_associated(
    ($obj || { type => $t, id => $id }), $group, $attributes)

 This will take an object ( or it's unique identifiers) and a group ( or it's 
 unique identifiers) and an optional set of attributes and will return the 
 member object if said object is a member of said group with the stated 
 attributes

B<throws:>
 None

B<side effects:>
 None

B<notes:>

=cut


#--------------------------------------#
# Public Instance Methods               

=item $name = $group->get_name( )

 Returns the name that has been given to the group

B<throws:>
 None

B<side effects:>
 None

B<notes:>

=cut

sub get_name {

}

=item $group = $group->set_name( $name )

 sets the name to the given name

B<throws:>
 None

B<side effects:>
 None

B<notes:>

=cut

sub set_name {

}

=item $desc = $group->get_description( )

 Returns the description that was given to the group 

B<throws:>
 None

B<side effects:>
 None

B<notes:>

=cut

sub get_description {

}

=item $group = $group->set_description( $desc )

 Sets the description to the given argument

B<throws:>
 None

B<side effects:>
 None

B<notes:>

=cut

sub set_description {

}

=item $id = $group->get_id()

 Returns the database id of the group object

B<throws:>
 None

B<side effects:>
 None

B<notes:>
 None

=cut

sub get_id {

}

=item $group = $group->activate()

 makes an inactive group active again

B<throws:>
 None

B<side effects:>
 None

B<notes:>
 None

=cut

sub activate {

}

=item $group = $group->deactivate()

 Makes a group inactive

B<throws:>
 None

B<side effects:>
 None

B<notes:>
 None

=cut


sub deactivate {

}

=item (1 || undef ) = $group->is_active()

 Returns 1 if the group is active, undef if it is inactive

B<throws:>
 None

B<side effects:>
 None

B<notes:>
 None

=cut
 

sub is_active {

}

=item $success = $group->set_members(
	[{obj => ($obj || $unique_ids), attr => $attributes }]); 

 Takes a list of hash refs with the keys ob obj which has a value of the 
 object (or its unique identifiers) and attr which will be the attributes that
 are placed on the member object.   This will add the object to the group.

B<throws:>
 None

B<side effects:>
 None

B<notes:>
 None

=cut

sub set_members {

}

=item (@members || $member_aref) = $group->get_members();

 Returns a list or a list ref of the member objects that are in the group

B<throws:>
 None 

B<side effects:>
 None 

B<notes:>
 None

=cut



sub get_members {

}


=item $success = $self->delete_members([$obj||$members||{type=>$t,id=>$id}]);

 Takes a lsit of objects or their unique identifiers ard removes them from the
 group

B<throws:>
 None 

B<side effects:>
 None 

B<notes:>
 None

=cut


sub delete_members {

}


=item ($member || undef) = $group->has_member(
	( {type=> $t,id=> $id} || $obj), $attr);

 Responds with the member object if object is a member or undef otherwise

B<throws:>
 None 

B<side effects:>

B<notes:>
=cut


sub has_member {

}

=item $attr_obj = $group->get_attr_obj()

 Returns the attribute object that is associated with the group

B<throws:>
 None 

B<side effects:>
 None

B<notes:>
 None

=cut

sub get_attr_obj {

}

=item $group = $group->set_member_attrs(
	[ { name => $name, subsys => $subsys, value => $value } ] )

 Set default attributes for members of the group.   These can be over rided
 by setting the attributes of the member.

B<throws:>
 None 

B<side effects:>
 None

B<notes:>
 None

=cut


sub set_member_attrs {

}

=item (@vals || $val_aref) =
	$group->get_member_attrs( [ { name => $name, subsys => $subsys} ])

 Retrieves the value of the attribute that has been assigned as a default
 for members that has the given name and subsystem

B<throws:>
 None 

B<side effects:>
 None

B<notes:>

=cut


sub get_member_attrs {

}


=item (@vals || $val_aref) = $group->get_group_attrs( [ $name ])

 Get attributes that describe the group but do not apply to members.
 This retrieves the value in the attribute object from a special subsystem 
 which contains these.   This will be returned as a list of values

B<throws:>
 None 

B<side effects:>
 None

B<notes:>
 None

=cut


sub get_group_attrs {

}


=item $group = $group->set_group_attrs([{ name => $name, value => $value }])

 Sets attributes that describe the group but do not apply to members.
 This sets the value in the attribute object to a special subsystem 
 which contains these

B<throws:>
 None 

B<side effects:>
 None

B<notes:>
 None

=cut


sub set_group_attrs {

}

=item $group = $group->save()

 Updates the database to reflect the changes made to the object

B<throws:>
 None 

B<side effects:>
 None

B<notes:>
 None

=cut



#==============================================================================#
# Private Methods                      #
#======================================#

=head2 Private Methods

=cut

#--------------------------------------#
# Private Class Methods                 

# None

#--------------------------------------#
# Private Instance Methods              

# None
 
1;
__END__

=back

=head1 NOTES

 This module is still in progress.

=head1 AUTHOR

 michael soderstrom ( miraso@pacbell.net )

=head1 SEE ALSO

 Bric.pm

=cut
