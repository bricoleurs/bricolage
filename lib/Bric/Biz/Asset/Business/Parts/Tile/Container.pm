package Bric::Biz::Asset::Business::Parts::Tile::Container;
###############################################################################

=head1 NAME

Bric::Biz::Asset::Business::Parts::Tile::Container - The class that contains other
tiles

=head1 VERSION

$Revision: 1.18.4.5 $

=cut

our $VERSION = (qw$Revision: 1.18.4.5 $ )[-1];


=head1 DATE

$Date: 2004/02/29 20:10:09 $

=head1 SYNOPSIS

  # Creation of Objects
  $tile = Bric::Biz::Asset::Business::Parts::Tile::Container->new
    ($initial_state)
  $tile = Bric::Biz::Asset::Business::Parts::Tile::Container->lookup
    ({ id => $id })
  @tiles =
    Bric::Biz::Asset::Business::Parts::Tile::Container->list($params)
  @ids =
    Bric::Biz::Asset::Business::Parts::Tile::Container->list_ids($params)

  $tile = $tile->add_contained([$tiles])
  @tiles = $tile->get_contained;
  $tile = $tile->delete_contained([$tiles])
  $tile = $tile->is_container;
  $tile = $tile->reorder->(@new_order)


=head1 DESCRIPTION

This is the class for tiles that contain other tiles. These can be data tiles
and or other container tiles.

=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies
use strict;

#--------------------------------------#
# Programatic Dependencies
use Bric::Util::DBI qw(:all);
use Bric::Biz::Asset::Business::Parts::Tile::Data;
use Bric::Biz::AssetType;

#==============================================================================#
# Inheritance                          #
#======================================#

# The parent module should have a 'use' line if you need to import from it.
use base qw( Bric::Biz::Asset::Business::Parts::Tile );

#=============================================================================#
# Function Prototypes                  #
#======================================#

# None

#==============================================================================#
# Constants                            #
#======================================#

use constant DEBUG => 0;

use constant S_TABLE => 'story_container_tile';

use constant M_TABLE => 'media_container_tile';

use constant COLS => qw(name
                        description
                        element__id
                        object_instance_id
                        parent_id
                        place
                        object_order
                        related_instance__id
                        related_media__id
                        active);
use constant FIELDS => qw(name
                        description 
                        element_id
                        object_instance_id
                        parent_id
                        place
                        object_order
                        related_instance_id
                        related_media_id
                        _active);

#==============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields
# None.

#--------------------------------------#
# Private Class Fields
# None.

#--------------------------------------#
# Instance Fields

# This method of Bricolage will call 'use fields' for you and set some permissions.
BEGIN {
        Bric::register_fields({
                        # Public Fields

                        # reference to the asset type data object
                        element_id          => Bric::FIELD_RDWR,
                        object_order           => Bric::FIELD_RDWR,
                        object_instance_id     => Bric::FIELD_RDWR,
                        related_instance_id    => Bric::FIELD_RDWR,
                        related_media_id       => Bric::FIELD_RDWR,

                        # Private Fields
                        _del_tiles            => Bric::FIELD_NONE,
                        _tiles                => Bric::FIELD_NONE,
                        _update_tiles         => Bric::FIELD_NONE,

                        _update_contained     => Bric::FIELD_NONE,

                        _active               => Bric::FIELD_NONE,
                        _object               => Bric::FIELD_NONE,
                        _element_obj          => Bric::FIELD_NONE,
                        _related_instance_obj => Bric::FIELD_NONE,
                        _related_media_obj    => Bric::FIELD_NONE,
                        _prepare_clone        => Bric::FIELD_NONE,
                        _delete               => Bric::FIELD_NONE


        });
}

#==============================================================================#
# Interface Methods                    #
#======================================#

=head1 INTERFACE

=head2 Constructors

=over 4

=item $tile = Bric::Biz::Asset::Business::Parts::Tile::Container->new($init)

This will create a new tile object with the given state defined by the
optional initial state argument

Supported Keys:

=over 4

=item *

obj_type

=item *

obj_id

=item *

element__id

=item *

active

=item *

parent_id

=item *

place

=back

B<Throws:>

=over 4

=item *

Object of type $class not allowed

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub new {
    my ($self, $init) = @_;

    # check active and object
    $init->{'_active'} = (exists $init->{'active'}) ? $init->{'active'} : 1;
    delete $init->{'active'};
    $init->{'place'}  ||= 0;
    $init->{'object_order'} ||=1;
    $self = bless {}, $self unless ref $self;

    if ($init->{'object'}) {
        $init->{'object_instance_id'} = $init->{'object'}->get_version_id();
        my $class = ref $init->{'object'};
        if ($class =~ /^Bric::Biz::Asset::Business::Media/) {
            $init->{'object_type'} = 'media';
        } elsif ($class eq 'Bric::Biz::Asset::Business::Story') {
            $init->{'object_type'} = 'story';
        } else {
            die Bric::Util::Fault::Exception::GEN->new( {
              msg => "Object of type $class not allowed"});
        }
        $init->{'_object'} = delete $init->{'object'};
    }

    if ($init->{'element'} ) {
        $init->{'element_id'} = $init->{'element'}->get_id();
        $init->{'_element_obj'} = delete $init->{'element'};
    } else {
        # not sure why this needs to be here
        delete $init->{'element'};
        $init->{'_element_obj'} = Bric::Biz::AssetType->lookup({
          'id' => $init->{'element_id'} });
    }

    $init->{'name'} = $init->{'_element_obj'}->get_name();
    $init->{'description'} = $init->{'_element_obj'}->get_description();
    $self->SUPER::new($init);

    # prepopulate from the asset type object
    my $parts = $init->{'_element_obj'}->get_data();
    unless ($init->{'object_type'}) {
        die Bric::Util::Fault::Exception::GEN->new( {
          msg => "Cannot create with out object type." });
    }

    foreach (@$parts) {
        if ($_->get_required()) {
            $self->add_data($_);
        }
    }

    $self->_set__dirty(1);
    return $self;
}

################################################################################

=item $tile = Bric::Biz::Asset::Business::Parts::Tile->lookup( { id => $id } )

This method. will return an existing tile object that is defined by the given ID.

B<Throws:>

=over 4

=item *

Missing required Parameter 'id'.

=item *

Missing required Parameter 'object_type' or 'object'".

=item *

Improper type of object passed to lookup

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub lookup {
    my ($class, $param) = @_;
    my $self = $class->cache_lookup($param);
    return $self if $self;

    # bless the new object
    $self = bless {}, $class;

    # Check for the proper args
    die Bric::Util::Fault::Exception::GEN->new
      ({ msg => "Missing required Parameter 'id'" })
        unless defined $param->{'id'};
    die Bric::Util::Fault::Exception::GEN->new
      ({ 'msg' => "Missing required Parameter 'object_type' or 'object'"})
        unless $param->{'object'} || $param->{'object_type'};

    if ($param->{'obj'}) {
        # get the package to determine the object field
        my $obj_class = ref $param->{'object'};

        if ($obj_class eq 'Bric::Biz::Asset::Business::Story') {
            # set object type to story and add the object
            $self->_set( { object_type => 'story',
                           _object     => $param->{'object'} });

        } elsif ($obj_class eq 'Bric::Biz::Asset::Business::Media') {
            $self->_set( { object_type => 'media',
                           _object     => $param->{'object'} });
        } else {
            die Bric::Util::Fault::Exception::GEN->new
              ({ msg => 'Improper type of object passed to lookup' });
        } # end the if obj block
    } else {
        $self->_set( { 'object_type' => $param->{'object_type'} } );
    }

    # Call private method to populate the object; return undef if it fails
    return unless $self->_select_container('id=?', $param->{'id'});

    $self->SUPER::new;
    $self->_set__dirty(0);
    return $self;
}

################################################################################

=item (@tiles||$tiles) = Bric::Biz::Assets::Parts::Tile::Container->list($param)

This will return a list or list ref of tiles that match the given criteria

Supported Keys:

=over 4

=item object

The object to search for containers - must be a Bric::Biz::Asset::Business
subclass. You must specify this parameter or object_type.

=item object_type

The type of object to find containers for - 'story' or 'media'. You must
specify this parameter or object.

=item active

Find inactive stuff by setting this to 0, active with 1.

=item element_id

Find containers of a particular AssetType.

=item name

The name of the AssetType for the container

=item parent_id

Find containers with a given parent container.

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE

=cut

sub list {
    my ($class, $param) = @_;
    _do_list($class,$param,undef);
}

################################################################################

#--------------------------------------#

=back

=head2 Destructors

=over 4

=item $self->DESTROY

=cut

sub DESTROY {
    # This method should be here even if its empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

################################################################################

#--------------------------------------#

=back

=head2 Public Class Methods

=over 4

=item (@ids||$ids) = Bric::Biz::Assets::Parts::Tile::Container->list_ids($param)

This will return a list or list ref of tile ids that match the given criteria

Supported Keys are the same as for C<list()>

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub list_ids {
    my ($class, $param) = @_;
    _do_list($class, $param, 1);
}

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item $id = $container->get_related_instance_id()

Returns the ID of the story instance related to this container tile

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

=item $container = $container->set_related_instance_id($id)

Set the ID of the story instance related to this container tile

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $story = $container->get_related_story()

Instantiate the related instance to this container tile based on the id. This
named 'get_related_story' rather than 'get_related_instance' since that is how
the template designer who will use this will probably expect it to work (ie,
they probably won't think in terms of an instance'.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_related_story {
    my $self = shift;
    my $dirty = $self->_get__dirty;
    my ($rel_id, $rel_obj) = $self->_get('related_instance_id',
                                         '_related_instance_obj');

    # Return with nothing if there is no related instance ID
    return unless $rel_id;

    # Clear the object cache if the ID has changed.
    $rel_obj = undef if $rel_obj and ($rel_obj->get_id != $rel_id);

    unless ($rel_obj) {
        $rel_obj = Bric::Biz::Asset::Business::Story->lookup({'id' => $rel_id});
        $self->_set(['_related_instance_obj'], [$rel_obj]) if $rel_obj;
        $self->_set__dirty($dirty);
    }

    return $rel_obj;
}

################################################################################

=item $tile = $tile->set_related_media($media)

Sets the media object that is related to this container

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub set_related_media {
    my ($self, $media) = @_;
    my $media_id;

    if (ref $media) {
        $media_id = $media->get_id;
        $self->_set(['_related_media_obj'], [$media]);
    } else {
        $media_id = $media;
    }

    $self->_set(['related_media_id'], [$media_id]);

    return $self;
}

################################################################################

=item $media = $tile->get_related_media()

Returns the media object that is related to this tile

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_related_media {
    my ($self) = @_;
    my $dirty = $self->_get__dirty;
    my ($media_id, $media_obj) = $self->_get('related_media_id',
                                             '_related_media_obj');

    return unless $media_id;

    # Clear the object cache if the IDs change.
    $media_obj = undef if $media_obj and $media_obj->get_id != $media_id;

    unless ($media_obj) {
        $media_obj = Bric::Biz::Asset::Business::Media->lookup({id => $media_id});
        $self->_set({'_related_media_obj' => $media_obj});
        $self->_set__dirty($dirty);
    }
    return $media_obj;
}

################################################################################

=item $name = $container->get_element()

Returns the element object

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_element {
    my ($self) = @_;
    return $self->_get_element_obj();
}

################################################################################

=item $name = $container->get_element_name()

Returns the name of the element

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_element_name {
    my ($self) = @_;
    my $at = $self->_get_element_obj();
    return $at->get_name;
}

################################################################################

=item ($data || @data) = $container->get_possible_data()

Returns the data fields that are allowed to be added to the container at this
moment. Takes into account the current set of data elements added.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_possible_data {
    my ($self) = @_;
    my $current = $self->_get_tiles();
    my $at      = $self->_get_element_obj();
    my %at_info = map { $_->get_id => $_ } $at->get_data;
    my @parts;

    foreach (@$current) {
        # Skip container tiles
        next if $_->is_container();

        my $id  = $_->get_element_data_id();
        my $atd = delete $at_info{$id};

        next unless $atd;

        # Add if this tile is repeatable.
        push @parts, $atd if $atd->get_quantifier;
    }

    # Add the container tiles (the only things remaining in this hash)
    @parts = sort { $a->get_place <=> $b->get_place } @parts, values %at_info;

    return wantarray ? @parts : \@parts;
}

################################################################################

=item (@tiles || $tiles) = $container->get_possible_containers()

Returns a list of the possible containers that can be added to this
object. This is synonymous with AssetType->get_containers() since containers
don't support occurence constraints.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_possible_containers {
    my ($self) = @_;
    my $at = $self->_get_element_obj();
    my $cont = $at->get_containers();
    return wantarray ? @$cont : $cont;
}

################################################################################

=item $container = $container->add_data($atd, $data, ?$place?);

Takes an asset type data object and the data and creates a tile and then adds
the tile to its self. Optionally accepts an $place argument to set the place
property. Now that's service.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub add_data {
    my ($self, $atd, $data, $place) = @_;
    my $data_tile = Bric::Biz::Asset::Business::Parts::Tile::Data->new
      ({ active             => 1,
         object_type        => $self->_get('object_type'),
         object_instance_id => $self->_get('object_id'),
         element_data       => $atd,
       });

    $data_tile->set_data($data);
    $self->add_tile($data_tile);

    # have to do this after add_tile() since add_tile() modifies place
    $data_tile->set_place($place) if defined $place;
    return $self;
}

################################################################################

=item $new_container = $container->add_container()

Given an asset type and the business asset this will create a new container
tile and return it after adding it to this list

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub add_container {
    my ($self, $atc) = @_;

    # create a new Container Object with this one as its parent
    my $container_tile = Bric::Biz::Asset::Business::Parts::Tile::Container->new
      ({ active             => 1,
         object_type        => $self->_get('object_type'),
         object_instance_id => $self->_get('object_id'),
         element            => $atc,
         parent_id          => $self->_get('id') });

    $self->add_tile($container_tile);
    return $container_tile;
}

################################################################################

=item $string = $tile->get_data($name, $obj_order)

=item $string = $tile->get_data($name, $obj_order, $date_format)

This method will search the contained tiles for one with the coresponding name
ane object order field. It will then return the data from that data tile. Pass
in the optional C<$date_format> argument if you expect the data returned from
C<$name> to be of the date type, and you'd like a format other than that set
in the "Date Format" preference.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_data {
    my ($self, $name, $obj_order, $dt_fmt) = @_;
    $obj_order = 1 unless defined $obj_order;

    foreach my $t ($self->_get_tiles) {
        return $t->get_data($dt_fmt) if not $t->is_container
          and $t->has_name($name) and $t->get_object_order == $obj_order;
    }
    # Well, I suppose that there were no matches.
    return;
}

################################################################################

=item $contained = $container->get_container($name, $obj_order)

Similar to get data this will return a container object that matches the given
name field and object order description.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_container {
    my ($self, $name, $obj_order) = @_;
    $obj_order = 1 unless defined $obj_order;

    foreach my $t ($self->_get_tiles) {
        return $t if $t->is_container and $t->has_name($name)
          and $t->get_object_order == $obj_order;
    }
    # Well, I suppose that there were no matches.
    return;
}

################################################################################

=item (@containers || $containers) = $tile->get_containers()

returns a list of the sub contained tiles

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_containers {
    my ($self) = @_;

    my @containers = grep($_->is_container, @{$self->_get_tiles()});

    return wantarray ? @containers : \@containers if scalar @containers;
    return;
}

################################################################################

=item (@tile_ids||$tile_ids_aref) = $tile->get_tiles()

Returns a list of the tiles that are contained with in the 
container tile

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_elements { get_tiles(@_) }

sub get_tiles {
    my ($self) = @_;
    my $tiles = $self->_get_tiles();
    return wantarray ? @$tiles : $tiles;
}

################################################################################


=item $tile = $tile->add_tile($tile)

Adds the given tile to this container. The tile will become a child of this
container and will be given an order with respect to the other child tiles
already in this container.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub add_tile {
    my ($self, $tile) = @_;
    my $dirty = $self->_get__dirty;

    # Get the children of this object
    my $tiles = $self->_get_tiles() || [];

    # Die if an ID is passed rather than an object.
    unless (ref $tile) {
        my $msg = 'Must pass objects, not IDs';
        die Bric::Util::Fault::Exception::GEN->new({'msg' => $msg});
    }

    # Set the place for this part.  This will be updated when its added.
    $tile->set_place(scalar (@$tiles));

    # Determine if this tile is a container.
    my $is_cont = $tile->is_container;
    # Get the apporopriate asset type ID.
    my $at_id = $is_cont ? $tile->get_element_id()
                         : $tile->get_element_data_id();

    # Figure out how many tiles of the same type as the tile we're adding exist.
    my $object_order = 1;
    foreach (@$tiles) {
        # Do an XOR test to make sure we deal with objects of the same type.
        if ($_->is_container() && $is_cont) {
            $object_order++ if $_->get_element_id      == $at_id;
        } elsif (not $_->is_container && not $is_cont) {
            $object_order++ if $_->get_element_data_id == $at_id;
        }
    }

    # Start numbering at one.
    $tile->set_object_order($object_order);

    push @$tiles, $tile;

    # Update $self's new and deleted tiles lists.
    $self->_set(['_tiles', '_update_tiles'], [$tiles, 1]);

    # We do not need to update the container object itself.
    $self->_set__dirty($dirty);

    return $self;
}

################################################################################

=item $tile = $tile->delete_tiles->( [ $tile || { type => $type, id => $id } ] )

Removes the tiles listed from the container

B<Throws:> NONE.

B<Side Effects:> Will shift the remaining tiles to fit. So if tiles with ids
of 2, 4, 7, 8, and 10 are contained and 4 and 8 are removed the new list of
tiles will be 2,7, and 10

B<Notes:> Doesn't actually do any deletions, just schedules them. Call
C<save()> to complete the deletion.

=cut

sub delete_tiles {
    my ($self, $tiles_arg) = @_;
    my (%del_data, %del_cont, $error);

    my $err_msg = 'Improper args to delete tiles';

    foreach (@$tiles_arg) {
        if (ref $_ eq 'HASH') {
            die Bric::Util::Fault::Exception::GEN->new({msg => $err_msg})
              unless (exists $_->{'id'} && exists $_->{'type'});

            if ($_->{'type'} eq 'data') {
                $del_data{$_->{'id'}} = undef;
            } elsif ($_->{'type'} eq 'container') {
                $del_cont{$_->{'id'}} = undef;
            } else {
                die Bric::Util::Fault::Exception::GEN->new({msg => $err_msg});
            }
        } elsif (ref $_ eq 'Bric::Biz::Asset::Business::Parts::Tile::Data') {
            $del_data{$_->get_id()} = undef;
        } elsif (ref $_ eq 'Bric::Biz::Asset::Business::Parts::Tile::Container') {
            $del_cont{$_->get_id()} = undef;
        } else {
            die Bric::Util::Fault::Exception::GEN->new({msg => $err_msg});
        }
    }

    my $tiles = $self->_get('_tiles');
    my $del_tiles = $self->_get('_del_tiles') || [];

    my $order = 0;
    my $cont_order;
    my $data_order;
    my $new_list;
    foreach (@$tiles) {
        my $delete = undef;
        if ($_->is_container) {
            if (exists $del_cont{$_->get_id}) {
                push @$del_tiles, $_;
                                $delete = 1;
            }
        } else {
            if (exists $del_data{$_->get_id}) {
                push @$del_tiles, $_;
                $delete = 1;
            }
        }

        unless ($delete) {
            my $count;
            $_->set_place($order);
            if ($_->is_container()) {
                if (exists $cont_order->{$_->get_element_id }) {
                    $count = scalar @{ $cont_order->{$_->get_element_id } };
                } else {
                    $count = 0;
                    $cont_order->{$_->get_element_id } = [];
                }
                $_->set_object_order($count);
            } else {
                if (exists $data_order->{ $_->get_element_data_id }) {
                    $count = scalar
                      @{ $data_order->{$_->get_element_data_id } };
                } else {
                    $count = 0;
                    $data_order->{$_->get_element_data_id } = [];
                }
                $_->set_object_order($count);
                push @{ $data_order->{$_->get_element_data_id} },
                  $_->get_id;
            }
            push @$new_list, $_;
            $order++;
        }
    }

    $self->_set(['_tiles',  '_del_tiles', '_update_tiles'],
                [$new_list, $del_tiles,   1]);
    return $self;
}

################################################################################

=item $container = $container->perpare_clone()

When a business asset needs to clone its self. It can call this here method
that will set the id to undef so that this here tile will clone its self.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub prepare_clone {
    my ($self) = @_;

    my $tiles = $self->_get_tiles();
    foreach (@$tiles) {
        $_->prepare_clone();
    }

    $self->_set(['id',  '_update_tiles'],
                [undef, 1]);

    return $self;
}

################################################################################

=item $tile = $tile->reorder_tiles( @new_order )

Takes a new order of tile ids as its argument and replaces the old order

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub reorder_tiles {
    my ($self, $new_order) = @_;
    my $dirty = $self->_get__dirty;
    my $tiles = $self->_get_tiles();
    my ($at_count, $data_count) = ({},{});
    my @new_list;

    # make sure then number of elements passed is the same as what we have
    if (scalar @$tiles != scalar @$new_order ) {
        die Bric::Util::Fault::Exception::GEN->new( {
          msg => 'Improper number of args to reorder_tiles().' });
    }

    # Order the tiles in the order they are listed in $new_order
    foreach my $obj (@$new_order) {

        # Set this tiles place among other tiles.
        my $new_place = scalar @new_list;
        $obj->set_place($new_place) 
          unless $obj->get_place == $new_place;
        push @new_list, $obj;

        # Get the appropriate asset type ID and 'seen' hash.
        my ($at_id, $seen);
        if ($obj->is_container()) {
            $at_id = $obj->get_element_id;
            $seen  = $at_count;
        } else {
            $at_id = $obj->get_element_data_id;
            $seen  = $data_count;
        }

        # Set this tiles place among other tiles of its type.
        my $n = $seen->{$at_id} || 1;
        my $new_obj_order = $n++;
        $obj->set_object_order($new_obj_order)
          unless $obj->get_object_order == $new_obj_order;
        $seen->{$at_id} = $n;
    }

    $self->_set(['_tiles', '_update_tiles'], [\@new_list, 1]);
    $self->_set__dirty($dirty);
    return $self;
}

################################################################################

=item ($self || undef) $self->is_container();

will return true since this is a container. You did look at the package name,
no? This is helpfuld for people cycling through contained tiles so they can
decide to call get_contained or get data

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub is_container { $_[0]; }

###############################################################################

=item $ct = $ct->do_delete()

Prepares this tile and its children to be removed

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE

=cut

sub do_delete {
    my $self = shift;
    $self->_set([qw(object_instance_id _delete)], [undef, 1]);
}

################################################################################

=item $ct = $ct->save()

This will insert or update the records as is needed

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub save {
    my ($self) = @_;

    if ($self->_get__dirty) {
        if ($self->_get('id') ) {
            if ($self->_get('_delete')) {
                $self->_do_delete();
                return $self;
            }
            # call private update method
            $self->_do_update;
        } else {
            # call private insert method
            $self->_do_insert;
        }
    }

    $self->_sync_tiles();

    # call the parents save method
    $self->SUPER::save();

    $self->_set__dirty(0);

    return $self;
}

################################################################################

=back

=head1 PRIVATE

=head2 Private Class Methods

=over 4

=item _do_list()

Called by list and list_ids, this does their dirty work

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _do_list {
    my ($class, $param, $ids) = @_;
    die Bric::Util::Fault::Exception::GEN->new( {
                        msg => "improper args for list" })
      unless ($param->{'object'} || $param->{'object_type'});

    my ($obj_type, $obj_id, $table);

    if ($param->{'object'}) {
        my $obj_class = ref $param->{'object'};
        if ($obj_class eq 'Bric::Biz::Asset::Business::Story') {
            $table = S_TABLE;
            $obj_type = 'story';
        } elsif ($obj_class =~ /^Bric::Biz::Asset::Business::Media/) {
            $table = M_TABLE;
            $obj_type = 'media';
        } else {
            die Bric::Util::Fault::Exception::GEN->new(
              { msg => "Object of type $obj_class not allowed to be tiled" });
        }
        $obj_id = $param->{'object'}->get_version_id();

    } else {
        if ($param->{'object_type'} eq 'story') {
            $table = S_TABLE;
        } elsif ($param->{'object_type'} eq 'media') {
            $table = M_TABLE;
        } else {
            my $msg = "Object of type $param->{'object_type'} not allowed ".
              "to be tiled";
            die Bric::Util::Fault::Exception::GEN->new( { msg => $msg });
        }
    }

    my (@where, @where_param);

    if ($obj_id) {
        push @where, " object_instance_id=? ";
        push @where_param, $obj_id;
    }
    if (exists $param->{'active'} ) {
        push @where, ' active=? ';
        push @where_param, $param->{'active'};
    }
    if (exists $param->{'parent_id'}) {
        if (defined $param->{'parent_id'}) {
            push @where, 'parent_id=?';
            push @where_param, $param->{'parent_id'};
        } else {
            push @where, 'parent_id IS NULL';
        }
    }
    if ($param->{'element_id'} ) {
        push @where, ' element__id=? ';
        push @where_param, $param->{'element_id'};
    }
    if ($param->{'name'}) {
        push @where, ' name=? ';
        push @where_param, $param->{'name'};
    }

    my $sql;
    if ($ids) {
        $sql = "SELECT id FROM $table ";
    } else {
        $sql = 'SELECT id, ' . join(', ', COLS) . " FROM $table ";
    }

    if (@where) {
        $sql .= ' WHERE ';
        $sql .= join ' AND ', @where;
    }
    my $select = prepare_ca( $sql, undef);

    if ($ids) {
        my $return = col_aref($select,@where_param);
        return wantarray ? @{ $return } : $return;
    } else {
        my @objs;
        execute($select, @where_param);
        my @cols;
        bind_columns($select, \@cols[0 .. scalar COLS]);
        while (fetch($select) ) {
            my $self = bless {}, $class;
            $self->_set( [ 'id', FIELDS ], [@cols] );
            # FIX THIS SHIT
            my $ot = $obj_type || $param->{'object_type'};
            $self->_set( { 'object_type' => $ot });
            $self->_set__dirty(0);
            push @objs, $self->cache_me;
        }
        return wantarray ? @objs : \@objs;
    }
}

################################################################################

=back

=head2 Private Instance Methods

=over 4

=item $self = $self->_do_delete()

Removes this record from the database

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _do_delete {
    my ($self) = @_;

    my $sql = ' DELETE FROM ';
    $sql .= ($self->_get('object_type') eq 'media') ? M_TABLE : S_TABLE;
    $sql .= ' WHERE id=? ';

    my $sth = prepare_c($sql, undef);
    execute($sth, $self->_get('id'));
    return $self;
}

=item $self = $self->_select_container($param)

This will do a select and populate the object with the row

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _select_container {
    my ($self, $where, @bind) = @_;
    my @d;

    my $sql = 'SELECT id,'. join(', ', COLS);
    if ($self->_get('object_type') eq 'story' ) {
        $sql .= " FROM " . S_TABLE;

    } elsif ($self->_get('object_type') eq 'media') {
        $sql .= " FROM " . M_TABLE;

    } else {
        # this is here just in case
        die Bric::Util::Fault::Exception->new
          ({ msg => "Improper Object type has been defined" });
    }

    $sql .= " WHERE $where";

    my $sth = prepare_ca($sql, undef, 1);
    execute($sth, @bind);
    bind_columns($sth, \@d[0 .. (scalar COLS)]);
    fetch($sth);

    # Return undef unless the ID column is defined.
    return unless $d[0];

    # set the values retrieved
    $self->_set(['id', FIELDS], [@d]);
    return $self->cache_me;
}

################################################################################

=item $at_obj = $self->_get_element_obj()

Returns the asset type object that maps to this container tile

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _get_element_obj {
    my ($self) = @_;
    my $dirty = $self->_get__dirty;
    my ($at_obj, $at_id) = $self->_get('_element_obj', 'element_id');

    unless ($at_obj) {
        $at_obj = Bric::Biz::AssetType->lookup({id => $at_id});
        $self->_set(['_element_obj'], [$at_obj]);
        $self->_set__dirty($dirty);
    }
    return $at_obj;
}

################################################################################

=item _do_insert

Inserts a row relating to this object into the data base

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _do_insert {
    my ($self) = @_;

    # get the short name
    my $type = $self->_get('object_type');
    my $table;
    if ($type eq 'story') {
        $table = S_TABLE;
    } elsif ($type eq 'media') {
        $table =  M_TABLE
    } else {
        die Bric::Util::Fault::Exception::GEN->new
          ({ 'msg' => 'Object must be a media or story to add tiles' });
    }

    my $sql = "INSERT INTO $table " .
      "(id, " . join(', ', COLS) . ") " .
      "VALUES (${\next_key($table)}, " .
      join(',', ('?') x COLS) . ") ";

    my $insert = prepare_c($sql, undef);
    execute($insert, ($self->_get( FIELDS )) ); 
    $self->_set( { 'id' => last_key($table) });
    return $self;
}

################################################################################

=item $self = $self->_do_update()

This will preform an update on the database.   That is why I called it
do update

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _do_update {
    my ($self) = @_;

    my $short = $self->_get('object_type');

    my $table;
    if ($short eq 'story') {
        $table = S_TABLE;
    } elsif ($short eq 'media') {
        $table = M_TABLE;
    } else {
        die Bric::Util::Fault::Exception::GEN->new
          ({ msg => 'only story and media objects may have tiles' });
    }

    my $sql = "UPDATE $table " .
      " SET " . join(', ', map { "$_=?" } COLS) .
      ' WHERE id=? ';

    my $update = prepare_c($sql, undef);
    execute($update, ($self->_get( FIELDS )), $self->_get('id') );
    return $self;
}

################################################################################

=item _get_contained

does a list for all the active contained tiles

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _get_tiles {
    my ($self) = @_;
    my $dirty = $self->_get__dirty;
    my $tiles = $self->_get('_tiles');

    # Do not attempt to get the AssetType tiles if we don't yet have an ID.
    return [] unless $tiles || $self->get_id;

    unless ($tiles) {
        my $cont = Bric::Biz::Asset::Business::Parts::Tile::Container->list
          ({
            parent_id   => $self->get_id,
            active      => 1,
            object_type => $self->_get('object_type')
           });

        my $data = Bric::Biz::Asset::Business::Parts::Tile::Data->list
          ({
            parent_id   => $self->get_id,
            active      => 1,
            object_type => $self->_get('object_type')
           });

        $tiles = [sort { $a->get_place <=> $b->get_place } (@$cont, @$data)];
        $self->_set(['_tiles', '_update_tiles'], [$tiles, 0]);
        $self->_set__dirty($dirty);
    }

    return wantarray ? @$tiles : $tiles;
}

################################################################################

=item $self->_sync_tiles()

Called by save this will preform all the operations on the contained tiles

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _sync_tiles {
    my ($self) = @_;
    my ($tiles,$del_tiles) = $self->_get('_tiles', '_del_tiles');

    # HACK. I don't think that this was really necessary, because each tile
    # wil only be saved and trigger a change to the database if it was
    # actually changed in some way. This is similar to how collections work.
    # So I'm commenting this out and just saving all the tiles every time.
    # -DW 2003-04-12.
#    return unless $self->_get('_update_tiles');

    foreach (@$tiles) {
#               if ($prep_clone) {
#                       $_->prepare_clone;
#                       $self->_set( { '_prepare_clone' => undef });
#               }

        # just in case this is an insert but only if its changed.
        my $id = $self->get_id;
        my $pid = $_->get_parent_id;
        $_->set_parent_id($id) unless defined $pid && $pid == $id;

        # same here
        my $inst_id = $self->get_object_instance_id;
        my $old_iid = $_->get_object_instance_id;
        $_->set_object_instance_id($inst_id) 
          unless defined $old_iid && $old_iid == $inst_id;

        $_->save();
    }

    while (my $t = shift @$del_tiles) {
        $t->set_object_order(0);
        $t->set_place(0);
        $t->deactivate();
        $t->save()
    }

    $self->_set(['_update_tiles'], [0]);
    return $self;
}

################################################################################

1;
__END__

=back

=head1 NOTES

NONE

=head1 AUTHOR

"Michael Soderstrom" <miraso@pacbell.net>
Bricolage Engineering

=head1 SEE ALSO

L<perl>, L<Bric>, L<Bric::Biz::Asset>, L<Bric::Biz::Asset::Business>,
L<Bric::Biz::Asset::Business::Parts::Tile>

=cut

