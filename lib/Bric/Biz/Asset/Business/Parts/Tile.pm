package Bric::Biz::Asset::Business::Parts::Tile;
###############################################################################

=head1 NAME

Bric::Biz::Asset::Business::Parts::Tile - Tile maps a particular Asset Part
Data object to a formatting Asset

=head1 VERSION

$Revision: 1.13 $

=cut

our $VERSION = (qw$Revision: 1.13 $ )[-1];

=head1 DATE

$Date: 2004-01-15 16:39:54 $

=head1 SYNOPSIS

 ($tile_list,@tiles) = Bric::Biz::Asset::Business::Parts::Tile->list($criteria)

 $id = $tile->get_id()

 $tile = $tile->activate()

 $tile = $tile->deactivate()

 (undef || 1) $tile->is_active()

 $tile = $tile->save()

=head1 DESCRIPTION

Tile maps the asset part to a particular formatting asset. There are data
tiles which map to the particular data points and container tiles that contain
other tiles.

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
# None.

#--------------------------------------#
# Private Class Fields
my ($METHS, @ORD);

#--------------------------------------#
# Instance Fields

BEGIN {
    Bric::register_fields(
               {
                # Public Fields

                # A name for this tile that can be displayed
                'name'                          => Bric::FIELD_RDWR,

                # A unique name for this tile to be used internal
                'key_name'                      => Bric::FIELD_RDWR,

                # A short description of this tile
                'description'                   => Bric::FIELD_RDWR,

                # the parent id of this tile
                'parent_id'                     => Bric::FIELD_RDWR,

                # the order in which this tile should be returned
                'place'                         => Bric::FIELD_RDWR,

                # The data base id of the Tile
                'id'                            => Bric::FIELD_RDWR,

                # The type of object that this tile is associated with
                # will also be used to determine what table to put the data into
                # ( story || media )
                'object_type'           => Bric::FIELD_RDWR,

                # the id of the object that this is a tile for
                'object_id'                     => Bric::FIELD_RDWR,

                # Private Fields

                # the reference to the object
                '_object'                       => Bric::FIELD_NONE,

                # The active flag
                '_active'                       => Bric::FIELD_NONE

        });
}

#==============================================================================#
# Interface Methods                    #
#======================================#

=head1 INTERFACE

=head2 Constructors

=over 4

=cut

#--------------------------------------#
# Constructors
#------------------------------------------------------------------------------#

=item $tile = Bric::Biz::Asset::Business::Parts::Tile->new( {format => $fa})

This will return a new Tile object with the optional initial state of format
and data

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

=item ($tile_list, @tiles) = Bric::Biz::Asset::Business::Parts::Tile->list
        ( $criteria )

This will return a list ( or list ref) of tile objects that match the given
criteria.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub list {
    throw_mni(error => 'Method not Implemented');
}

################################################################################

#--------------------------------------#

=back

=head2 Destructors

=over 4

=item $self->DESTROY

this is a dummy method to save time going through auto load

=cut

sub DESTROY {
    # This method should be here even if its empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

#--------------------------------------#

=back

=head2 Public Class Methods

=over 4

=item $meths = Bric::Biz::Asset::Business::Parts::Tile->my_meths

=item (@meths || $meths_aref) = Bric::Biz::Asset::BusinessParts::Tile->my_meths(TRUE)

=item my (@meths || $meths_aref) = Bric::Biz:::Asset::BusinessParts::Tile->my_meths(0, TRUE)

Returns an anonymous hash of introspection data for this object. If called
with a true argument, it will return an ordered list or anonymous array of
introspection data. If a second true argument is passed instead of a first,
then a list or anonymous array of introspection data will be returned for
properties that uniquely identify an object (excluding C<id>, which is
assumed).

Each hash key is the name of a property or attribute of the object. The value
for a hash key is another anonymous hash containing the following keys:

=over 4

=item *

name - The name of the property or attribute. Is the same as the hash key when
an anonymous hash is returned.

=item *

disp - The display name of the property or attribute.

=item *

get_meth - A reference to the method that will retrieve the value of the
property or attribute.

=item *

get_args - An anonymous array of arguments to pass to a call to get_meth in
order to retrieve the value of the property or attribute.

=item *

set_meth - A reference to the method that will set the value of the
property or attribute.

=item *

set_args - An anonymous array of arguments to pass to a call to set_meth in
order to set the value of the property or attribute.

=item *

type - The type of value the property or attribute contains. There are only
three types:

=over 4

=item short

=item date

=item blob

=back

=item *

len - If the value is a 'short' value, this hash key contains the length of the
field.

=item *

search - The property is searchable via the list() and list_ids() methods.

=item *

req - The property or attribute is required.

=item *

props - An anonymous hash of properties used to display the property or attribute.
Possible keys include:

=over 4

=item type

The display field type. Possible values are

=item text

=item textarea

=item password

=item hidden

=item radio

=item checkbox

=item select

=back

=item *

length - The Length, in letters, to display a text or password field.

=item *

maxlength - The maximum length of the property or value - usually defined by the
SQL DDL.

=item *

rows - The number of rows to format in a textarea field.

=item *

cols - The number of columns to format in a textarea field.

=item *

vals - An anonymous hash of key/value pairs reprsenting the values and display
names to use in a select list.

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut


sub my_meths {
    my ($pkg, $ord, $ident) = @_;
    return if $ident;

    # We don't got 'em. So get 'em!
    $METHS ||= {
                name        => { name     => 'name',
                                 get_meth => sub { shift->get_name(@_) },
                                 get_args => [],
                                 set_meth => sub { shift->set_name(@_) },
                                 set_args => [],
                                 disp     => 'Name',
                                 type     => 'short',
                                 len      => 256,
                                 req      => 1,
                                 props    => { type      => 'text',
                                               length    => 32,
                                               maxlength => 256
                                             }
                               },

                key_name    => { name     => 'key_name',
                                 get_meth => sub { shift->get_name(@_) },
                                 get_args => [],
                                 set_meth => sub { shift->set_name(@_) },
                                 set_args => [],
                                 disp     => 'Key Name',
                                 type     => 'short',
                                 len      => 256,
                                 req      => 1,
                                 props    => { type      => 'text',
                                               length    => 32,
                                               maxlength => 256
                                             }
                               },

                description => { name     => 'description',
                                 get_meth => sub { shift->get_description(@_) },
                                 get_args => [],
                                 set_meth => sub { shift->set_description(@_) },
                                 set_args => [],
                                 disp     => 'Description',
                                 len      => 256,
                                 type     => 'short',
                                 props    => { type => 'textarea',
                                               cols => 40,
                                               rows => 4
                                             }
                               }
               };

    return !$ord ? $METHS : wantarray ? @{$METHS}{@ORD} : [@{$METHS}{@ORD}];
}

##############################################################################

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
    throw_mni(error => 'Method Not Implemented');
}

################################################################################

#--------------------------------------#

=back

=head2 Public Instance Methods

=over 4

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
    my $name = $self->get_key_name;
    $test_name =~ y/a-z0-9/_/cs;
    return $name eq lc($test_name);
}

################################################################################

=item (1 || 0) = $tile->has_key_name($key_name);

Test to see whether this tile has a key name matching the argument $key_name.
Returns 1 if the name is a match and 0 otherwise.

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut

sub has_key_name {
    my $self = shift;
    my ($test_name) = @_;

    return $self->get_key_name eq $test_name;
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

=item $parent_element = $tile->get_parent()

Returns the parent element object.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_parent {
    my $self = shift;
    my $pid = $self->_get('parent_id') or return;
    Bric::Biz::Asset::Business::Parts::Tile::Container->lookup({ id => $pid });
}

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

=back

=head1 PRIVATE

NON

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

michael soderstrom ( miraso@pacbell.net )

=head1 SEE ALSO

L<perl>,L<Bric>,L<Bric::Biz::Asset::Business::Story>,L<Bric::Biz::Asset_type>,
L<Bric::Biz::Asset_type::Parts::Data>,L<Bric::Biz::Asset::Business::Media> 

=cut

