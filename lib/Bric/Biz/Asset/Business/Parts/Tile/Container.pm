package Bric::Biz::Asset::Business::Parts::Tile::Container;
###############################################################################

=head1 NAME

Bric::Biz::Asset::Business::Parts::Tile::Container - Container Element

=head1 VERSION

$LastChangedRevision$

=cut

require Bric; our $VERSION = Bric->VERSION;


=head1 DATE

$LastChangedDate$

=head1 SYNOPSIS

  # Creation of Objects
  my $container = Bric::Biz::Asset::Business::Parts::Tile::Container->new($init);
  my $container = Bric::Biz::Asset::Business::Parts::Tile::Container->lookup({
    id => $id
  });
  my @containers = Bric::Biz::Asset::Business::Parts::Tile::Container->list($params);
  my @ids = Bric::Biz::Asset::Business::Parts::Tile::Container->list_ids($params);

  $container = $container->add_element(\@containers);
  my @elements = $container->get_elements;
  $container = $container->delete_elements(\@containers);
  $container = $container->is_container;
  $container = $container->reorder->(@new_order);

=head1 DESCRIPTION

This class contains the contents of container elements, also known as story
type elements, media type elements, and container subelements. These objects
can contain one or more subelements, and those subelements can be either data
elements or other container elements. This class inherits from
L<Bric::Biz::Asset::Business::Parts::Tile|Bric::Biz::Asset::Business::Parts::Tile>.

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
use Bric::App::Util;
use Bric::Util::Fault qw(throw_gen);

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
                        key_name
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
                          key_name
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
                        element_id             => Bric::FIELD_RDWR,
                        related_instance_id    => Bric::FIELD_RDWR,
                        related_media_id       => Bric::FIELD_RDWR,

                        # Private Fields
                        _del_subelems         => Bric::FIELD_NONE,
                        _subelems             => Bric::FIELD_NONE,
                        _update_subelems      => Bric::FIELD_NONE,

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

=item my $container = Bric::Biz::Asset::Business::Parts::Tile::Container->new($init)

Construct a new container element object. The supported initial attributes are:

=over 4

=item object_type

A string identifying the type of document the new container element is
associated with. It's value can be "story " or "media".

=item object_instance_id

The ID of the story or media document the new container element is associated
with.

=item place

The order of this element relative to the other subelements of the parent
element.

=item object_order

The order of this element relative to the other container elements based on
the same Bric::Biz::AsetType object that are subelements of the parent
element.

=item parent_id

The ID of the container element that is the parent of the new container
element.

=item element

A Bric::Biz::AssetType object that defines the structure of this container
element.

=item element_id

An ID for the Bric::Biz::AssetType object that defines the structure of this
container element.

=item active

A boolean value indicating whether the container element is active or
inactive.

=back

B<Throws:>

=over 4

=item Object of type not allowed.

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
        $init->{'object_instance_id'} = $init->{'object'}->get_id();
        my $class = ref $init->{'object'};
        if ($class eq 'Bric::Biz::Asset::Business::Parts::Instance::Story') {
            $init->{'object_type'} = 'story';
        } elsif ($class eq 'Bric::Biz::Asset::Business::Parts::Instance::Media') {
            $init->{'object_type'} = 'media';
        } else {
            throw_gen(error => "Object of type $class not allowed");
        }
#        if ($class =~ /^Bric::Biz::Asset::Business::Media/) {
#            $init->{'object_type'} = 'media';
#        } elsif ($class =~ /^Bric::Biz::Asset::Business::Story/) {
#            $init->{'object_type'} = 'story';
#        } else {
#            throw_gen(error => "Object of type $class not allowed");
#        }
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

    $init->{'name'}        = $init->{'_element_obj'}->get_name();
    $init->{'key_name'}    = $init->{'_element_obj'}->get_key_name();
    $init->{'description'} = $init->{'_element_obj'}->get_description();
    $self->SUPER::new($init);

    # prepopulate from the asset type object
    my $parts = $init->{'_element_obj'}->get_data();
    unless ($init->{'object_type'}) {
        throw_gen(error => "Cannot create with out object type.");
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

=item my $container = Bric::Biz::Asset::Business::Parts::Tile->lookup($params)

Looks up a container element in the database by its ID and returns it. The
lookup parameters are:

=over 4

=item id

The ID of the conainer element to lookup. Required.

=item object

A story or media document object with which the conainer element is
associated. Required unless C<object_type> is specified.

=item object_type

The type of document object with which the container element is associated.
Must be either "media" or "story". Required unless C<object> is specified.

=back

B<Throws:>

=over 4

=item Missing required Parameter 'id'.

=item Missing required Parameter 'object_type' or 'object'.

=item Improper type of object passed to lookup.

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
    throw_gen(error => "Missing required Parameter 'id'")
        unless defined $param->{'id'};
    throw_gen(error => "Missing required Parameter 'object_type' or 'object'")
        unless $param->{'object'} || $param->{'object_type'};

    if ($param->{object}) {
        # get the package to determine the object field
        my $obj_class = ref $param->{object};

        if ($obj_class eq 'Bric::Biz::Asset::Business::Story') {
            # set object type to story and add the object
            $self->_set( { object_type => 'story',
                           _object     => $param->{object} });

        } elsif ($obj_class eq 'Bric::Biz::Asset::Business::Media') {
            $self->_set( { object_type => 'media',
                           _object     => $param->{object} });
        } else {
            throw_gen(error => 'Improper type of object passed to lookup');
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

=item my @containers = Bric::Biz::Assets::Parts::Tile::Container->list($param)

Searches for and returns a list or anonymous array of container element
objects. The supported parameters that can be searched are:

=over 4

=item object

A story or media object with which the container elements are associated.
Required unless C<object_type> is specified.

=item object_type

The type of document with which the container elements are associated.
Required unless C<object> is specified.

=item object_instance_id

The ID of a story or container object with wich the container elements are
associated. Can only be used if C<object_type> is also specified and
C<object> is not specified.

=item name

The name of the container elements. Since the SQL C<LIKE> operator is used with
this search parameter, SQL wildcards can be used.

=item key_name

The key name of the container elements. Since the SQL C<LIKE> operator is used with
this search parameter, SQL wildcards can be used.

=item parent_id

The ID of the container element that is the parent element of the container
elements. Pass C<undef> to this parameter to specify that the C<parent_id>
must be C<NULL>.

=item element_id

The ID of the Bric::Biz::AssetType object that specifies the structure of the
container elements.

=item active

A boolean value indicating whether the returned data elements are active or
inactive.

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

=item $container->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

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

=item my @ids = Bric::Biz::Assets::Parts::Tile::Container->list_ids($param)

Returns a list or anonymous array of container element IDs. The search
parameters are the same as for C<list()>.

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

See also
L<Bric::Biz::Asset::Business::Parts::Tile|Bric::Biz::Asset::Business::Parts::Tile>,
from which Bric::Biz::Asset::Business::Parts::Tile::Container inherits.

=over 4

=item my $element_id = $container->get_element_id

Returns the ID of the Bric::Biz::AssetType object that defines the structure
of this element.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $container->set_element_id($element_id)

Sets the ID of the Bric::Biz::AssetType object that defines the structure
of this element.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $object_order = $container->get_object_order

Returns the order number for this object relative to other container elements
based on the same Bric::Biz::AssetType object.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $container->set_object_order($object_order)

Sets the order number for this object relative to other container elements
based on the same Bric::Biz::AssetType object.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $story_id = $container->get_related_instance_id

Returns the ID of a story related to this container element.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $container->set_related_instance_id($story_id)

Sets the ID of a story related to this container element.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $media_id = $container->get_related_media_id

Returns the ID of a media document related to this container element.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $container->set_related_media_id($media_id)

Sets the ID of a media document related to this container element.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

################################################################################

=item $container->set_related_story($story)

Creates a relationship between the container element and a story document.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_related_story {
    my ($self, $story) = @_;
    my $story_id;

    if (ref $story) {
        $story_id = $story->get_id;
        $self->_set(['_related_intance_obj'], [$story]);
    } else {
        $story_id = $story;
    }

    $self->_set(['related_instance_id'], [$story_id]);
}

################################################################################

=item $story = $container->get_related_story

If a story is related to this container element, this method returns that
story object.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_related_story {
    my $self = shift;
    my $dirty = $self->_get__dirty;
    my ($rel_id, $rel_obj) = $self->_get('related_instance_id',
                                         '_related_instance_obj');

    # Return with nothing if there is no related instance ID
    return undef unless $rel_id;

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

=item $container->set_related_media($media)

Creates a relationship between the container element and a media document.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

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
}

################################################################################

=item $media = $container->get_related_media

If a media document is related to this container element, this method returns
that media object.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_related_media {
    my ($self) = @_;
    my $dirty = $self->_get__dirty;
    my ($media_id, $media_obj) = $self->_get('related_media_id',
                                             '_related_media_obj');

    return undef unless $media_id;

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

=item $obj = $container->get_element

Returns the Bric::Biz::AssetType object that defines the structure of this
container element.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_element {
    my $self = shift;
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

=item $name = $container->get_element_name

An alias for C<< $container->get_name >>.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_element_name { $_[0]->get_name }

################################################################################

=item $key_name = $container->get_element_key_name

An alias for C<< $container->get_key_name >>.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_element_key_name { $_[0]->get_key_name }

################################################################################

=item my @data = $container->get_possible_data

Returns a list or anonymous array of the Bric::Biz::AssetType::Parts::Data
objects that define the types of data elements that can be subelements of this
container element. This list would exclude any data elements that can only be
added as subelements to this container element once, and have already been
added.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_possible_data {
    my ($self) = @_;
    my $current = $self->get_elements();
    my $at      = $self->get_element();
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
    push @parts, values %at_info;

    return wantarray ? @parts : \@parts;
}

################################################################################

=item my @elements = $container->get_possible_containers

Returns a list or anonymous array of the Bric::Biz::AssetType::Parts::Data
objects that define the types of data elements that can be subelements of this
container element. This is synonymous with
C<< $container->get_element->get_containers >>, since containers do not
support occurence constraints.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_possible_containers {
    my $self = shift;
    my $at = $self->get_element or return;
    $at->get_containers;
}

################################################################################

=item $container = $container->add_data($atd, $value, $place);

Pass a Bric::Biz::AssetType::Parts::Data object and a value for a new data
element, and that new data element will be added as a subelement of the
container element. An optional third argument specifies the C<place> for that
data element in the order of subelements of this container element.

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

=item $new_container = $container->add_container($element)

Adds a new container subelement to this container element. Pass in the
required Bric::Biz::AssetType object specifying the structure of the new
container subelement.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

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

=item my $data = $element->get_data_element($key_name, $obj_order)

Returns a specific data subelement of this container element. Pass in the key
name of the data element to be retreived. By default, the first data element
with that key name will be returned. Pass in an optional second argument to
specify the C<object_order> of the data element to be retrieved.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_data_element {
    my ($self, $name, $obj_order) = @_;
    $obj_order = 1 unless defined $obj_order;
    foreach my $t ($self->get_elements) {
        return $t if not $t->is_container
          and $t->has_key_name($name)
          and $t->get_object_order == $obj_order;
    }
    return;
}

################################################################################

=item my @data = $container->get_data_elements

  my @data = $element->get_data_elements;
  @data = $element->get_data_elements(@key_names);

Returns a list or anonymous array of the data subelements of this element. If
called with no arguments, it returns all of the data subelements. If passed a
list of key names, the only the data subelements with those key names will be
returned.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_data_elements {
    my $self = shift;

    # Just return them all if no key names are passed.
    return wantarray
      ? (grep { ! $_->is_container } @{ $self->get_elements })
      : [grep { ! $_->is_container } @{ $self->get_elements }]
      unless @_;

    # Return only those with the specified key names.
    my %knames = map { $_ => 1} @_;
    return wantarray
      ? (grep { ! $_->is_container && $knames{$_->get_key_name} }
           @{ $self->get_elements })
      : [grep { ! $_->is_container && $knames{$_->get_key_name} }
           @{ $self->get_elements }];
}

################################################################################

=item $string = $element->get_data($key_name, $obj_order)

=item $string = $element->get_data($key_name, $obj_order, $date_format)

Returns the value of a specific data subelement of this container element.
Pass in the key name of the data element to be retreived. By default, the
first data element with that key name will be returned. Pass in an optional
second argument to specify the C<object_order> of the data element to be
retrieved. Pass in the optional C<$date_format> argument if you expect the
data returned from C<$key_name> to be of the date type, and you'd like a
format other than that set in the "Date Format" preference.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_data {
    my ($self, $name, $obj_order, $dt_fmt) = @_;

    # If we find any illegal characters, warn the user to start using the key
    # name rather than the display name.
    if ($name =~ /[^a-z0-9_]/) {
        ($name = lc($name)) =~ y/a-z0-9/_/cs;
        my $msg = "Warning:  Use of element's 'name' field is deprecated for use with element method 'get_data'.  Please use the element's 'key_name' field instead.";
        Bric::App::Util::add_msg($msg);
        warn $msg;
    }
    my $delem = $self->get_data_element($name, $obj_order) or return;
    return $delem->get_data($dt_fmt);
}

################################################################################

=item my $subelement = $container->get_container($key_name, $obj_order)

Returns a specific conainer subelement of this container element. Pass in the
key name of the container element to be retreived. By default, the first
container element with that key name will be returned. Pass in an optional
second argument to specify the C<object_order> of the container element to be
retrieved.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_container {
    my ($self, $name, $obj_order) = @_;

    # If we find any illegal characters, warn the user to start using the key
    # name rather than the display name.
    if ($name =~ /[^a-z0-9_]/) {
        ($name = lc($name)) =~ y/a-z0-9/_/cs;
        my $msg = "Warning:  Use of element's 'name' field is deprecated for use with element method 'get_container'.  Please use the element's 'key_name' field instead.";
        Bric::App::Util::add_msg($msg);
    }

    $obj_order = 1 unless defined $obj_order;

    foreach my $t ($self->get_elements) {
        return $t if $t->is_container        and
                     $t->has_key_name($name) and
                     $t->get_object_order == $obj_order;
    }

    # Well, I suppose that there were no matches.
    return;
}

################################################################################

=item my @containers = $container->get_containers

  my @containers = $element->get_containers;
  @containers = $element->get_containers(@key_names);

Returns a list or anonymous array of the container subelements of this
container subelement. If called with no arguments, it returns all of the
container subelements. If passed a list of key names, the only the container
subelements with those key names will be returned.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_containers {
    my $self = shift;

    # Just return them all if no key names are passed.
    return wantarray
      ? (grep { $_->is_container } @{ $self->get_elements })
      : [grep { $_->is_container } @{ $self->get_elements }]
      unless @_;

    # Return only those with the specified key names.
    my %knames = map { $_ => 1} @_;
    return wantarray
      ? (grep { $_->is_container && $knames{$_->get_key_name} }
           @{ $self->get_elements })
      : [grep { $_->is_container && $knames{$_->get_key_name} }
           @{ $self->get_elements }];
}

################################################################################

=item my @subelements = $container->get_elements

=item my @subelements = $container->get_elements(@key_names)

Returns a list or anonymous array of all of the data and container subelements
of this container subelement, in the order specified by their C<place>
attributes. If called with no arguments, it returns all of the subelements. If
passed a list of key names, the only the subelements with those key names will
be returned.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_elements {
    my $self = shift;
    my $dirty = $self->_get__dirty;
    my $subelems = $self->_get('_subelems');

    # Do not attempt to get the AssetType tiles if we don't yet have an ID.
    return wantarray ? () : [] unless $subelems || $self->get_id;

    unless ($subelems) {
        my $cont = Bric::Biz::Asset::Business::Parts::Tile::Container->list({
            parent_id   => $self->get_id,
            active      => 1,
            object_type => $self->_get('object_type')
        });

        my $data = Bric::Biz::Asset::Business::Parts::Tile::Data->list({
            parent_id   => $self->get_id,
            active      => 1,
            object_type => $self->_get('object_type')
        });

        $subelems = [sort { $a->get_place <=> $b->get_place } (@$cont, @$data)];
        $self->_set(['_subelems', '_update_subelems'], [$subelems, 0]);
        $self->_set__dirty($dirty);
    }

    # Just return them all if no key_names are specified.
    return wantarray ? @$subelems : $subelems unless @_;

    my %knames = map { $_ => 1} @_;
    return wantarray
      ? (grep { $knames{$_->get_key_name} } @$subelems)
      : [grep { $knames{$_->get_key_name} } @$subelems];
}

=item my @elements = $container->get_tiles

An alias for C<get_elements()>, provided for backwards compatability.

=cut

sub get_tiles { shift->get_elements(@_) }

################################################################################

=item $container->add_element($subelement)

Adds an element to the current container element as a subelement. It will be
given a C<place> attribute and an C<object_order> attribute relative to the
other subelements of this container element.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub add_element {
    my ($self, $tile) = @_;
    my $dirty = $self->_get__dirty;

    # Get the children of this object
    my $tiles = $self->get_elements() || [];

    # Die if an ID is passed rather than an object.
    unless (ref $tile) {
        my $msg = 'Must pass objects, not IDs';
        throw_gen(error => $msg);
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
    $self->_set(['_subelems', '_update_subelems'], [$tiles, 1]);

    # We do not need to update the container object itself.
    $self->_set__dirty($dirty);

    return $self;
}

=item $container->add_tile($subelement)

An alias for C<add_element()>, provided for backwards compatability.

=cut

sub add_tile { shift->add_element(@_) }

################################################################################

=item $container->delete_tiles(\@subelements)

Removes the specified subelements from the current element. The arguments that
can be passed via the array reference can be either container or data element
objects or hash references with the following keys:

=over

=item type

The type of element to be deleted. The value of this parameter must be either
"data" or "container".

=item id

The ID of the element to be deleted.

=back

B<Throws:> NONE.

B<Side Effects:> Will shift and reorder the remaining subelements to fit. So
if telements with IDs of 2, 4, 7, 8, and 10 are contained and 4 and 8 are
removed the new list of tiles will be 2, 7, and 10

B<Notes:> Doesn't actually do any deletions, just schedules them. Call
C<save()> to complete the deletion.

=cut

sub delete_elements {
    my ($self, $tiles_arg) = @_;
    my (%del_data, %del_cont, $error);

    my $err_msg = 'Improper args to delete tiles';

    foreach (@$tiles_arg) {
        if (ref $_ eq 'HASH') {
            throw_gen(error => $err_msg)
              unless (exists $_->{'id'} && exists $_->{'type'});

            if ($_->{'type'} eq 'data') {
                $del_data{$_->{'id'}} = undef;
            } elsif ($_->{'type'} eq 'container') {
                $del_cont{$_->{'id'}} = undef;
            } else {
                throw_gen(error => $err_msg);
            }
        } elsif (ref $_ eq 'Bric::Biz::Asset::Business::Parts::Tile::Data') {
            $del_data{$_->get_id()} = undef;
        } elsif (ref $_ eq 'Bric::Biz::Asset::Business::Parts::Tile::Container') {
            $del_cont{$_->get_id()} = undef;
        } else {
            throw_gen(error => $err_msg);
        }
    }

    my $tiles = $self->_get('_subelems');
    my $del_tiles = $self->_get('_del_subelems') || [];

    my $order = 0;
    my $cont_order;
    my $data_order;
    my $new_list = [];
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

    $self->_set(['_subelems',  '_del_subelems', '_update_subelems'],
                [$new_list, $del_tiles,   1]);
    return $self;
}

=item $container->delete_tiles(\@subelements)

An alias for C<delete_elements()>, provided for backwards compatability.

=cut

sub delete_tiles { shift->delete_elements(@_) }

################################################################################

=item $container->prepare_clone

Prepares the conainer element to be cloned, such as when a new version of a
document is created, or when a document itself is cloned.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub prepare_clone {
    my $self = shift;
    for my $e ($self->get_elements) {
        $e->prepare_clone;
    }

    $self->_set(['id',  '_update_subelems'],
                [undef, 1]);
}

################################################################################

=item $container->reorder_elements(\@subelements)

Pass in an array reference of subelements in the order they are to be placed
relative to one another, and they will be reordered in that order.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub reorder_elements {
    my ($self, $new_order) = @_;
    my $dirty = $self->_get__dirty;
    my $tiles = $self->get_elements();
    my ($at_count, $data_count) = ({},{});
    my @new_list;

    # make sure then number of elements passed is the same as what we have
    if (scalar @$tiles != scalar @$new_order ) {
        throw_gen(error => 'Improper number of args to reorder_tiles().');
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

    $self->_set(['_subelems', '_update_subelems'], [\@new_list, 1]);
    $self->_set__dirty($dirty);
    return $self;
}

=item $container->reorder_tiles(\@subelements)

An alias for C<reorder_elements()>, provided for backwards compatability.

=cut

sub reorder_tiles { shift->reorder_elements(@_) }

################################################################################

=item my $is_container $container->is_container;

Returns true, since container elements are, in fact, container elements.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub is_container { $_[0] }

###############################################################################

=item $container->do_delete

Prepares this container element and its subelements to be removed.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE

=cut

sub do_delete {
    my $self = shift;
    $self->_set([qw(object_instance_id _delete)], [undef, 1]);
}

################################################################################

=item $container->save

Saves the changes to the container element to the database.

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

    $self->_sync_elements();

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

=item Bric::Biz::Asset::Business::Parts::Tile::Container->_do_list($class, $param, $ids)

Called by C<list()> or C<list_ids()>, this method returns either a list of ids
or a list of objects, depending on the third argument.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _do_list {
    my ($class, $param, $ids) = @_;
    throw_gen(error => "improper args for list")
      unless ($param->{'object'} || $param->{'object_type'});

    my ($obj_type, $obj_id, $table);

    if ($param->{'object'}) {
        my $obj_class = ref $param->{'object'};
        if ($obj_class eq 'Bric::Biz::Asset::Business::Parts::Instance::Story') {
            $table = S_TABLE;
            $obj_type = 'story';
        } elsif ($obj_class eq 'Bric::Biz::Asset::Business::Parts::Instance::Media') {
            $table = M_TABLE;
            $obj_type = 'media';
        } else {
            throw_gen(error => "Object of type $obj_class not allowed to be tiled");
        }
        $obj_id = $param->{'object'}->get_id();

    } else {
        if ($param->{'object_type'} eq 'story') {
            $table = S_TABLE;
        } elsif ($param->{'object_type'} eq 'media') {
            $table = M_TABLE;
        } else {
            my $msg = "Object of type $param->{'object_type'} not allowed ".
              "to be tiled";
            throw_gen(error => $msg);
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
    if ($param->{'key_name'}) {
        push @where, ' key_name=? ';
        push @where_param, $param->{'key_name'};
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

=item $container->_do_delete

Called by C<save()>, this method deletes the container element from the database.

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

##############################################################################

=item $container->_select_container($param)

Called by C<lookup()>, this method actually looks a container element up in
the database.

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
        throw_gen(error => "Improper Object type has been defined");
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

=item $container->_do_insert()

Called by C<save()>, this method inserts the container element into the
database.

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
        throw_gen(error => 'Object must be a media or story to add tiles');
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

=item $container->_do_update

Called by C<save()>, this method updates the container element into the
database.

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
        throw_gen(error => 'only story and media objects may have tiles');
    }

    my $sql = "UPDATE $table " .
      " SET " . join(', ', map { "$_=?" } COLS) .
      ' WHERE id=? ';

    my $update = prepare_c($sql, undef);
    execute($update, ($self->_get( FIELDS )), $self->_get('id') );
    return $self;
}

################################################################################

=item $container->_sync_elements

Called by C<save()> this method preforms all the operations on the subelements.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _sync_elements {
    my ($self) = @_;
    my ($tiles,$del_tiles) = $self->_get('_subelems', '_del_subelems');

    # HACK. I don't think that this was really necessary, because each tile
    # will only be saved and trigger a change to the database if it was
    # actually changed in some way. This is similar to how collections work.
    # So I'm commenting this out and just saving all the tiles every time.
    # -DW 2003-04-12.
#    return unless $self->_get('_update_subelems');

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

    $self->_set(['_update_subelems'], [0]);
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

