package Bric::Biz::Asset::Business::Parts::Tile;
###############################################################################

=head1 NAME

 Bric::Biz::Asset::Business::Parts::Tile

 Tile maps a particular Asset Part Data object to a formatting Asset

=head1 VERSION

$Revision: 1.5 $

=cut

our $VERSION = (qw$Revision: 1.5 $ )[-1];


=head1 DATE

$Date: 2001-11-20 00:02:44 $


=head1 SYNOPSIS

 ($tile_list,@tiles) = Bric::Biz::Asset::Business::Parts::Tile->list($criteria)

 $id = $tile->get_id()

 $tile = $tile->activate()

 $tile = $tile->deactivate()

 (undef || 1) $tile->is_active()

 $tile = $tile->save()

=head1 DESCRIPTION

Tile maps the asset part to a particular formatting asset.   There are data 
tiles which map to the particular data points and container tiles that 
contain other tiles.

=cut

#==============================================================================## Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies                 

use strict;

#--------------------------------------#
# Programatic Dependencies              

use Bric::Util::Fault::Exception::MNI;

#==============================================================================## Inheritance                          #
#======================================#

# The parent module should have a 'use' line if you need to import from it.
# use Bric;
use base qw(Bric);

#=============================================================================#
# Function Prototypes                  #
#======================================#

# None

#==============================================================================## Constants                            #
#======================================#

# None

#==============================================================================## Fields                               #
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
		'name'				=> Bric::FIELD_RDWR,
		'description'		=> Bric::FIELD_RDWR,	

		# the parent id of this tile
		'parent_id'			=> Bric::FIELD_RDWR,

		# the order in which this tile should be returned
		'place'				=> Bric::FIELD_RDWR,

		# The data base id of the Tile
		'id'				=> Bric::FIELD_RDWR,

		# The type of object that this tile is associated with
		# will also be used to determine what table to put the data into
		# ( story || media )
		'object_type'		=> Bric::FIELD_RDWR,

		# the id of the object that this is a tile for
		'object_id'			=> Bric::FIELD_RDWR,

		# Private Fields

		# the reference to the object
		'_object'			=> Bric::FIELD_NONE,

		# The active flag
		'_active'			=> Bric::FIELD_NONE

	});
}

#==============================================================================## Interface Methods                    #
#======================================#

=head1 INTERFACE

=head2 Constructors

=over 4

=cut

#--------------------------------------#
# Constructors                          

#------------------------------------------------------------------------------#

=item $tile = Bric::Biz::Asset::Business::Parts::Tile->new( {format => $fa})

This will return a new Tile object with the optional initial state of 
format and data

Supported Keys:

=over 4

=item *

format

=back

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub new {
	my ($self, $init) = @_;

	$self = bless {}, $self unless ref $self;
	$self->SUPER::new($init) if $init;

	$self->_set__dirty(1);

	return $self;
}

################################################################################

=item lookup - Method not supported

To look up a particular tile object go to it's class directly

B<Throws:>

"Method not implemented"

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub lookup {
    my $err_msg = "Method not Implemented";
    die Bric::Util::Fault::Exception::MNI->new({'msg' => $err_msg});
}

################################################################################

=item ($tile_list, @tiles) = Bric::Biz::Asset::Business::Parts::Tile->list
	( $criteria )

This will return a list ( or list ref) of tile objects that match the 
given criteria

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut
 
sub list {
    my $err_msg = "Method not Implemented";
    die Bric::Util::Fault::Exception::MNI->new({'msg' => $err_msg});
}

################################################################################

#--------------------------------------#

=head2 Destructors

=item $self->DESTROY

this is a dummy method to save time going through auto load

=cut

sub DESTROY {
    # This method should be here even if its empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

#--------------------------------------#

=head2 Public Class Methods

=cut

=item list_ids - Method not implemented

If you want to get a list of objects just use list, if you only want the ids
go the the objects themselves

B<Throws:>

"Method Not Implemented"

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub list_ids {
	Bric::Util::Fault::Exception::MNI->new( {
			msg => "Method Not Implemented"
		});
}

################################################################################

#--------------------------------------#

=head2 Public Instance Methods

=cut

################################################################################

=item (1 || 0) = $tile->has_name($name);

Test to see whether this tile has a name matching the argument $name.  Returns
1 if the name is a match and 0 otherwise.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub has_name {
    my $self = shift;
    my ($test_name) = @_;
    my $name;

    # Lower case and strip down to alpha numerics
    ($name = lc($self->get_name)) =~ y/a-z0-9/_/cs;
    ($test_name = lc($test_name)) =~ y/a-z0-9/_/cs;

    return $name eq $test_name;
}

################################################################################

=item $id = $tile->get_id()

Returns the database id of the tile object

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $tile = $tile->activate()

Makes the tile active if it was deactivated

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub activate {
	my ($self) = @_;

	$self->_set( {'_active' => 1 });

	return $self;
}

################################################################################

=item $tile = $tile->deactivate()

Makes the tile inactive (deleted )

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub deactivate {
	my ($self) = @_;

	$self->_set( {'_active' => 0 });

	return $self;
}

################################################################################

=item ($tile || undef) $tile->is_active()

Returns 1 if the tile is active or undef if it has been deactivated

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub is_active {
	my ($self) = @_;


	return $self->_get('_active') ? $self : undef;
}

################################################################################

#==============================================================================#

=head1 PRIVATE

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

=head1 NOTES

NONE

=head1 AUTHOR

michael soderstrom ( miraso@pacbell.net )

=head1 SEE ALSO

L<perl>,L<Bric>,L<Bric::Biz::Asset::Business::Story>,L<Bric::Biz::Asset_type>,
L<Bric::Biz::Asset_type::Parts::Data>,L<Bric::Biz::Asset::Business::Media> 

=cut

