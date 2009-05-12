package Bric::Biz::Element::Container;

###############################################################################

=head1 Name

Bric::Biz::Element::Container - Container Element

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  # Creation of Objects
  my $container = Bric::Biz::Element::Container->new($init);
  my $container = Bric::Biz::Element::Container->lookup({
    id => $id
  });
  my @containers = Bric::Biz::Element::Container->list($params);
  my @ids = Bric::Biz::Element::Container->list_ids($params);

  $container = $container->add_element(\@containers);
  my @elements = $container->get_elements;
  $container = $container->delete_elements(\@containers);
  $container = $container->is_container;
  $container = $container->reorder->(@new_order);

=head1 Description

This class contains the contents of container elements, also known as story
type elements, media type elements, and container subelements. These objects
can contain one or more subelements, and those subelements can be either data
elements or other container elements. This class inherits from
L<Bric::Biz::Element|Bric::Biz::Element>.

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
use Bric::Biz::Element::Field;
use Bric::Biz::ElementType;
use Bric::App::Util;
use Bric::Config qw(:pod);
use Bric::Util::Fault qw(throw_gen throw_invalid throw_da throw_dp);
use URI;
use List::Util qw(reduce first);
use Text::LevenshteinXS;

#==============================================================================#
# Inheritance                          #
#======================================#

# The parent module should have a 'use' line if you need to import from it.
use base qw( Bric::Biz::Element );

#=============================================================================#
# Function Prototypes                  #
#======================================#

# None

#==============================================================================#
# Constants                            #
#======================================#

use constant DEBUG => 0;

use constant S_TABLE => 'story_element';
use constant M_TABLE => 'media_element';

my @COLS = qw(
    element_type__id
    object_instance_id
    parent_id
    place
    object_order
    displayed
    related_story__id
    related_media__id
    active
);

my @FIELDS = qw(
    element_type_id
    object_instance_id
    parent_id
    place
    object_order
    displayed
    related_story_id
    related_media_id
    _active
);

my @SEL_COLS = qw(
    e.id
    e.element_type__id
    et.name
    et.key_name
    et.description
    et.related_story
    et.related_media
    e.object_instance_id
    e.parent_id
    e.place
    e.object_order
    e.displayed
    e.related_story__id
    e.related_media__id
    e.active
);

my @SEL_FIELDS = qw(
    id
    element_type_id
    name
    key_name
    description
    relate_story
    relate_media
    object_instance_id
    parent_id
    place
    object_order
    displayed
    related_story_id
    related_media_id
    _active
);

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
        element_type_id    => Bric::FIELD_RDWR,
        related_story_id   => Bric::FIELD_RDWR,
        related_media_id   => Bric::FIELD_RDWR,
        displayed          => Bric::FIELD_RDWR,

        # Private Fields
        _del_subelems      => Bric::FIELD_NONE,
        _subelems          => Bric::FIELD_NONE,
        _update_contained  => Bric::FIELD_NONE,
        _active            => Bric::FIELD_NONE,
        _object            => Bric::FIELD_NONE,
        _element_type_obj  => Bric::FIELD_NONE,
        _related_story_obj => Bric::FIELD_NONE,
        _related_media_obj => Bric::FIELD_NONE,
        _prepare_clone     => Bric::FIELD_NONE,
        _delete            => Bric::FIELD_NONE,
    });
}

#==============================================================================#
# Interface Methods                    #
#======================================#

=head1 Interface

=head2 Constructors

=over 4

=item my $container = Bric::Biz::Element::Container->new($init)

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
the same Bric::Biz::AssetType object that are subelements of the parent
element.

=item displayed

Boolean indicating whether or not the container element's display is toggled
open in the document profile. Ignored for top-level container elements.

=item parent_id

The ID of the container element that is the parent of the new container
element.

=item element

A Bric::Biz::ElementType object that defines the structure of this container
element.

=item element_type_id

An ID for the Bric::Biz::ElementType object that defines the structure of this
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
    my ($class, $init) = @_;

    # check active and object
    $init->{_active} = (exists $init->{active}) ? delete $init->{active} : 1;
    $init->{place}        ||= 0;
    $init->{object_order} ||=1;

    # Find the document or document type.
    if (my $doc = delete $init->{object}) {
        $init->{object_instance_id} = $doc->get_version_id;
        $init->{object_type}        = $doc->key_name;
        $init->{_object}            = $doc;
    } else {
        throw_gen 'Cannot create without object type.'
            unless $init->{object_type}
    }

    # Check the document type.
    throw_gen "Object of type $class not allowed"
        unless $init->{object_type} eq 'story'
            || $init->{object_type} eq 'media';

    # Set up the element type.
    if (my $type = delete $init->{element_type} || delete $init->{element} ) {
        $init->{_element_type_obj} = $type;
        $init->{element_type_id} = $type->get_id;
    } else {
        $init->{_element_type_obj} = Bric::Biz::ElementType->lookup({
            'id' => $init->{element_type_id} ||= delete $init->{element_id}
        });
    }

    # Alias element type attributes and make it so...
    @{$init}{qw(name key_name description relate_story relate_media displayed)}
        = $init->{_element_type_obj}->_get(
            qw(name key_name description related_story related_media displayed)
        );

    my $self = $class->SUPER::new($init);

    # Prepopulate from the element type object
    foreach my $ft ($init->{_element_type_obj}->get_field_types) {
        if (my $min = $ft->get_min_occurrence) {
            $self->add_field($ft) for 1..$min;
        }
    }

    # Prepopulate the elements based on min occurrence
    foreach my $subet ($init->{_element_type_obj}->get_containers) {
        if (my $min = $subet->get_min_occurrence) {
            $self->add_container($subet) for 1..$min;
        }
    }

    $self->_set__dirty(1);
    return $self;
}

################################################################################

=item my $container = Bric::Biz::Element->lookup($params)

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

    # Check for the proper args
    throw_gen 'Missing required parameter "object" or "id" and "object_type"'
        unless $param->{object} || ($param->{id} || $param->{object_type});

    my $elems = _do_list($class, $param, undef);

    # Throw an exception if we looked up more than one site.
    throw_da "Too many $class objects found" if @$elems > 1;
    return $elems->[0];
}

################################################################################

=item my @containers = Bric::Biz::Element::Container->list($param)

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
associated. Can only be used if C<object_type> is also specified and C<object>
is not specified. May use C<ANY> for a list of possible values.

=item name

The name of the container elements. Since the SQL C<LIKE> operator is used
with this search parameter, SQL wildcards can be used. May use C<ANY> for a
list of possible values.

=item key_name

The key name of the container elements. Since the SQL C<LIKE> operator is used
with this search parameter, SQL wildcards can be used. May use C<ANY> for a
list of possible values.

=item description

The description of the container elements. Since the SQL C<LIKE> operator is
used with this search parameter, SQL wildcards can be used. May use C<ANY> for
a list of possible values.

=item parent_id

The ID of the container element that is the parent element of the container
elements. Pass C<undef> to this parameter to specify that the C<parent_id>
must be C<NULL>. May use C<ANY> for a list of possible values.

=item element_type_id

The ID of the Bric::Biz::ElementType object that specifies the structure of the
container elements. May use C<ANY> for a list of possible values.

=item related_story_id

The ID of a Bric::Biz::Asset::Business::Story object that may be related to
container elements. Pass C<undef> to this parameter to specify that the
C<parent_id> must be C<NULL>. May use C<ANY> for a list of possible values.

=item related_media_id

The ID of a Bric::Biz::Asset::Business::Media object that may be related to
container elements. Pass C<undef> to this parameter to specify that the
C<parent_id> must be C<NULL>. May use C<ANY> for a list of possible values.

=item displayed

A boolean value indicating whether the returned data elements should have
their display toggled open in the document profile.

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
    _do_list($class, $param, undef);
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

=item my @ids = Bric::Biz::Element::Container->list_ids($param)

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
L<Bric::Biz::Element|Bric::Biz::Element>,
from which Bric::Biz::Element::Container inherits.

=over 4

=item my $element_type_id = $container->get_element_type_id

Returns the ID of the Bric::Biz::ElementType object that defines the structure
of this element.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $container->set_element_type_id($element_type_id)

Sets the ID of the Bric::Biz::ElementType object that defines the structure
of this element.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_element_id {
    require Carp && Carp::carp(
        __PACKAGE__  . '::get_element_id is deprecated. '
        . 'Use get_element_type_id instead'
    );
    return shift->get_element_type_id;
}

sub set_element_id {
    require Carp && Carp::carp(
        __PACKAGE__  . '::set_element_id is deprecated. '
       . 'Use set_element_type_id instead'
   );
    return shift->set_element_type_id(@_);
}

##############################################################################

=item my $bool = $container->can_relate_story

Returns a true value if the container is allowed to have a related story, and
false if it is not.

=cut

sub can_relate_story { $_[0]->{relate_story} ? shift : undef }

=item my $bool = $container->can_relate_media

Returns a true value if the container is allowed to have a related media
document, and false if it is not.

=cut

sub can_relate_media { $_[0]->{relate_media} ? shift : undef }

##############################################################################

=item my $object_order = $container->get_object_order

Returns the order number for this object relative to other container elements
based on the same Bric::Biz::ElementType object.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $container->set_object_order($object_order)

Sets the order number for this object relative to other container elements
based on the same Bric::Biz::ElementType object.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $displayed = $container->get_displayed

Returns boolean value indicating whether or not the container element's display
should be toggled open in the document profile.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $container->set_displayed($displayed)

Sets the boolean value indicating whether or not the container element's
display should be toggled open in the document profile.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item my $story_id = $container->get_related_story_id

=item my $story_id = $container->get_related_instance_id

Returns the ID of a story related to this container element.
C<get_related_instance_id()> is provided for backwards compatability with
versions of Bricolage prior to 1.9.1.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $container->set_related_story_id($story_id)

=item $container->set_related_instance_id($story_id)

Sets the ID of a story related to this container element.
C<set_related_instance_id()> is provided for backwards compatability with
versions of Bricolage prior to 1.9.1.

B<Throws:>

=over

=item Element cannot have a related story

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_related_story_id {
    my ($self, $rel_id) = @_;
    return $self unless defined $rel_id;
    throw_dp 'Element "' . $self->get_name . '" cannot have a related story'
        unless $self->can_relate_story;
    return $self->_set(['related_story_id'] => [$rel_id]);
}

sub get_related_instance_id { shift->get_related_story_id }
sub set_related_instance_id { shift->set_related_story_id(@_) }

##############################################################################

=item my $media_id = $container->get_related_media_id

Returns the ID of a media document related to this container element.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=item $container->set_related_media_id($media_id)

Sets the ID of a media document related to this container element.

B<Throws:>

=over

=item Element cannot have a related media

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_related_media_id {
    my ($self, $rel_id) = @_;
    return $self unless defined $rel_id;
    throw_dp 'Element "' . $self->get_name . '" cannot have a related media'
        unless $self->can_relate_media;
    return $self->_set(['related_media_id'] => [$rel_id]);
}

################################################################################

=item $container->get_elem_occurrence($subelement->get_key_name)

Returns the number of subelements currently in this container
which match the name passed in.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_elem_occurrence{
    return scalar @{ shift->get_elements(@_) };
}

################################################################################

=item $container->get_field_occurrence($field_type->get_key_name)

Returns the number of fields currently in this container
which match the field name passed in.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_field_occurrence{
    return scalar @{ shift->get_fields(@_) };
}

################################################################################

=item $container->set_related_story($story)

Creates a relationship between the container element and a story document.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_related_story {
    my ($self, $story) = @_;

    if (ref $story) {
        return $self->_set(
            [ qw(related_story_obj related_story_id) ],
            [ $story,              $story->get_id    ]
        );
    }

    return $self->_set(['related_story_id'] => [$story]);
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
    my ($rel_id, $rel_obj) = $self->_get(qw(
        related_story_id
        _related_story_obj
    ));

    # Return with nothing if there is no related instance ID
    return undef unless $rel_id;

    # Retrieve the story if it isn't cached or the related ID has changed.
    unless ($rel_obj && $rel_obj->get_id == $rel_id) {
        my $dirty = $self->_get__dirty;
        $rel_obj = Bric::Biz::Asset::Business::Story->lookup({ id => $rel_id });
        $self->_set(['_related_story_obj'] => [$rel_obj]);
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

    if (ref $media) {
        return $self->_set(
            [ qw(related_media_obj related_media_id) ],
            [ $media,              $media->get_id    ]
        );
    }

    return $self->_set(['related_media_id'] => [$media]);
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
    my $self = shift;
    my ($rel_id, $rel_obj) = $self->_get(qw(
        related_media_id
        _related_media_obj
    ));

    # Return with nothing if there is no related instance ID
    return undef unless $rel_id;

    # Retrieve the media if it isn't cached or the related ID has changed.
    unless ($rel_obj && $rel_obj->get_id == $rel_id) {
        my $dirty = $self->_get__dirty;
        $rel_obj = Bric::Biz::Asset::Business::Media->lookup({ id => $rel_id });
        $self->_set(['_related_media_obj'] => [$rel_obj]);
        $self->_set__dirty($dirty);
    }

    return $rel_obj;
}

################################################################################

=item $obj = $container->get_element_type

Returns the Bric::Biz::ElementType object that defines the structure of this
container element.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> C<get_element()> has been deprecated in favor of this method.

=cut

sub get_element_type {
    my $self = shift;
    my ($at_obj, $at_id) = $self->_get('_element_type_obj', 'element_type_id');

    unless ($at_obj) {
        my $dirty = $self->_get__dirty;
        $at_obj = Bric::Biz::ElementType->lookup({id => $at_id});
        $self->_set(['_element_type_obj'], [$at_obj]);
        $self->_set__dirty($dirty);
    }
    return $at_obj;
}

sub get_element {
    require Carp && Carp::carp(
        __PACKAGE__ . '::get_element is deprecated. ' .
        'Use get_element_type() instead'
    );
    shift->get_element_type(@_);
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

=item $container->get_possible_field_types()

=item $container->get_possible_data()

  my @field_types = $container->get_possible_field_types();
     @field_types = $container->get_possible_data();

Returns a list or anonymous array of the Bric::Biz::ElementType::Parts::FieldType
objects that define the types of data elements that can be subelements of this
container element. This list would exclude any data elements that can only be
added as subelements to this container element a set number of times, and have
already been added that many times. This is the max_occurrence of that FieldType.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> C<get_possible_data()> is the deprecated form of this method.

=cut

sub get_possible_field_types {
    my ($self) = @_;
    my $current = $self->get_fields();
    my $at      = $self->get_element_type;
    my %at_info = map { $_->get_id => $_ } $at->get_field_types;
    my @parts;

    for my $data (@$current) {
        if (my $atd = delete $at_info{$data->get_field_type_id}) {
            my $max = $atd->get_max_occurrence;
            push @parts, $atd if !$max || $max > $self->get_field_occurrence($atd->get_key_name);
        }
    }

    # Add the container elements (the only things remaining in this hash)
    push @parts, values %at_info;

    return wantarray ? @parts : \@parts;
}

sub get_possible_data { shift->get_possible_field_types(@_) }

################################################################################

=item my @elementtypes = $container->get_possible_containers

Returns a list or anonymous array of the Bric::Biz::ElementType
objects that define the types of data elements that can be subelements of this
container element. This is synonymous with
C<< $container->get_element_type->get_containers >>, with the exception that
it will only return those containers that don't already have the max allowed
according to the max_occurrence.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_possible_containers {
    my $self = shift;
    my $at = $self->get_element_type or return;
    my $containers = $at->get_containers;
    my @possible_cons;

    for my $data (@$containers) {
        my $max = $data->get_max_occurrence;
        push @possible_cons, $data if !$max ||
            $max > $self->get_elem_occurrence($data->get_key_name);
    }

    return wantarray ? @possible_cons : \@possible_cons;
}

################################################################################

=item $container->add_field($field_type, $value, $place);

=item $container->add_data($field_type, $value, $place);

Pass a Bric::Biz::ElementType::Parts::FieldType object and a value for a new field
element, and that new field element will be created and added as a subelement
of the container element. An optional third argument specifies the C<place>
for that field element in the order of subelements of this container element.
This returns the field that was created/added.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub add_field {
    my ($self, $atd, $data, $place) = @_;
    # Get the field type

    if ($atd->get_max_occurrence &&
        ($self->get_field_occurrence($atd->get_key_name) >=
            $atd->get_max_occurrence)) {
        my $field_name = $atd->get_key_name;
        my $field_occurrence = $self->get_field_occurrence($field_name);
        my $field_max_occur = $atd->get_max_occurrence;
        # Throw an error
        throw_invalid
            error    => qq{Field "$field_name" cannot be added. There are already }
                      . qq{$field_occurrence fields of this type, with a max of $field_max_occur.},
            maketext => [
                'Field "[_1]" cannot be added. There are already '
              . '[quant,_2,field,fields] of this type, with a max of [_3].',
                $field_name,
                $field_occurrence,
                $field_max_occur,
            ]
        ;
    }

    my $field = Bric::Biz::Element::Field->new({
        active             => 1,
        object_type        => $self->_get('object_type'),
        object_instance_id => $self->_get('object_instance_id'),
        field_type         => $atd,
    });

    $field->set_value($data) if defined $data;
    $self->add_element($field);

    # have to do this after add_element() since add_element() modifies place
    $field->set_place($place) if defined $place;
    return $field;
}

sub add_data { shift->add_field(@_) }

################################################################################

=item $new_container = $container->add_container($element_type)

Adds a new container subelement to this container element. Pass in the
required element type (Bric::Biz::ElementType) object specifying the structure
of the new container subelement.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub add_container {
    my ($self, $atc) = @_;

    my $elem_key_name = $atc->get_key_name;
    my $parent_key_name = $self->get_key_name;
    my @subets = $self->get_element_type->get_containers($elem_key_name);

    # Throw an error if $subets[0] doesn't exist
    if (!($subets[0])) {
    throw_invalid
        error    => qq{$elem_key_name cannot be a subelement }
                  . qq{of $parent_key_name.},
        maketext => [ '[_1] cannot be a subelement of [_2].',
            $elem_key_name,
            $parent_key_name,
        ]
    ;
    }
    my $max_occur = $subets[0]->get_max_occurrence;

    if ($max_occur && ($self->get_elem_occurrence($atc->get_key_name) >=
            $max_occur)) {
        my $elem_name = $atc->get_key_name;
        my $elem_occurrence = $self->get_elem_occurrence($elem_name);
        # Throw an error
        throw_invalid
            error    => qq{Element "$elem_name" cannot be added. There are already }
                      . qq{$elem_occurrence elements of this type, with a max of $max_occur.},
            maketext => [
                'Element "[_1]" cannot be added. There are already '
              . '[quant,_2,element,elements] of this type, with a max of [_3].',
                $elem_name,
                $elem_occurrence,
                $max_occur,
            ]
        ;
    }

    # create a new Container Object with this one as its parent
    my $container = Bric::Biz::Element::Container->new({
        active             => 1,
        object_type        => $self->_get('object_type'),
        object_instance_id => $self->_get('object_instance_id'),
        element_type       => $atc,
        parent_id          => $self->_get('id'),
    });

    $self->add_element($container);
    return $container;
}

################################################################################

=item my $field = $element->get_field($key_name, $obj_order)

=item my $field = $element->get_data_element($key_name, $obj_order)

Returns a specific field subelement of this container element. Pass in the key
name of the field to be retreived. By default, the first field with that key
name will be returned. Pass in an optional second argument to specify the
C<object_order> of the field to be retrieved.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> C<get_data_element()> is the deprecated form of this method.

=cut

sub get_field {
    my ($self, $kn, $obj_order) = @_;
    $obj_order = 1 unless defined $obj_order;
    return first {
        !$_->is_container
        && $_->get_object_order == $obj_order
        && $_->get_key_name     eq $kn
    } $self->get_elements;
}

sub get_data_element { shift->get_field(@_) }

################################################################################

=item my @fields = $container->get_fields

=item my @fields = $container->get_data_elements

  my @data = $element->get_fields;
     @data = $element->get_fields(@key_names);
     @data = $element->get_data_elements;
     @data = $element->get_data_elements(@key_names);

Returns a list or anonymous array of the field subelements of this element. If
called with no arguments, it returns all of the field subelements. If passed a
list of key names, the only the field subelements with those key names will be
returned, in the order specified by their C<place> attributes.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> C<get_data_elements()> is the deprecated form of this method.

=cut

sub get_fields {
    my $self = shift;

    # Just return them all if no key names are passed.
    return wantarray
        ? ( grep { ! $_->is_container } @{ $self->get_elements } )
        : [ grep { ! $_->is_container } @{ $self->get_elements } ]
        unless @_;

    # Return only those with the specified key names.
    my %knames = map { $_ => undef } @_;
    return wantarray
      ? (grep { ! $_->is_container && exists $knames{$_->get_key_name} }
           @{ $self->get_elements })
      : [grep { ! $_->is_container && exists $knames{$_->get_key_name} }
           @{ $self->get_elements }];
}

sub get_data_elements { shift->get_fields(@_) }

################################################################################

=item $value = $element->get_value($key_name, $obj_order)

=item $value = $element->get_value($key_name, $obj_order, $date_format)

=item $value = $element->get_data($key_name, $obj_order)

=item $value = $element->get_data($key_name, $obj_order, $date_format)

Returns the value of a specific field subelement of this container element.
Pass in the key name of the field element to be retreived. By default, the
first field element with that key name will be returned. Pass in an optional
second argument to specify the C<object_order> of the field element to be
retrieved. Pass in the optional C<$date_format> argument if you expect the
value returned from C<$key_name> to be of the date type, and you'd like a
format other than that set in the "Date Format" preference.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> C<get_data()> is the deprecated form of this method.

=cut

sub get_value {
    my ($self, $key_name, $obj_order, $dt_fmt) = @_;
    # Be sure to always return a scalar value!
    my $delem = $self->get_field($key_name, $obj_order) or return undef;
    return $delem->get_value($dt_fmt);
}

sub get_data { shift->get_value(@_) }

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
    my ($self, $kn, $obj_order) = @_;
    $obj_order = 1 unless defined $obj_order;

    return first {
        $_->is_container
        && $_->get_object_order == $obj_order
        && $_->get_key_name     eq $kn
    } $self->get_elements;
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

    # Do not attempt to get the ElementType elements if we don't yet have an ID.
    return wantarray ? () : [] unless $subelems || $self->get_id;

    unless ($subelems) {
        my $type = $self->_get('object_type');
        my $cont = Bric::Biz::Element::Container->list({
            parent_id   => $self->get_id,
            active      => 1,
            object_type => $type,
        });

        my $data = Bric::Biz::Element::Field->list({
            parent_id   => $self->get_id,
            active      => 1,
            object_type => $type,
        });

        $subelems = [
            map  {         $_->[1]         }
            sort {   $a->[0] <=> $b->[0]   }
            map  { [ $_->get_place => $_ ] }
            @$cont, @$data
        ];
        $self->_set(['_subelems'] => [$subelems]);
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
other subelements of this container element. The newly added container element
will be returned.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub add_element {
    my ($self, $element) = @_;
    my $dirty = $self->_get__dirty;

    # Get the children of this object
    my $elements = $self->get_elements() || [];

    # Die if an ID is passed rather than an object.
    throw_gen 'Must pass element objects, not IDs'
        unless ref $element;

    # Set the place for this part. This will be updated when its added.
    $element->set_place(scalar @$elements);

    # Figure out how many existing elements are the same type as we're adding.
    my $object_order = 1;
    if ($element->is_container) {
        my $et_id = $element->get_element_type_id;
        for my $sub (grep { $_->is_container } @$elements) {
            $object_order++ if $sub->get_element_type_id == $et_id;
        }
    }

    else {
        my $ft_id = $element->get_field_type_id;
        for my $sub (grep { !$_->is_container } @$elements) {
            $object_order++ if $sub->get_field_type_id == $ft_id;
        }
    }

    # Set the object order.
    $element->set_object_order($object_order);

    push @$elements, $element;

    # Update $self's new and deleted elements lists.
    $self->_set(['_subelems'] => [$elements]);

    # We do not need to update the container object itself.
    $self->_set__dirty($dirty);

    return $element;
}

=item $container->add_tile($subelement)

An alias for C<add_element()>, provided for backwards compatability.

=cut

sub add_tile { shift->add_element(@_) }

################################################################################

=item $container->delete_elements(\@subelements)

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
if elements with IDs of 2, 4, 7, 8, and 10 are contained and 4 and 8 are
removed the new list of elements will be 2, 7, and 10

B<Notes:> Doesn't actually do any deletions, just schedules them. Call
C<save()> to complete the deletion.

=cut

sub delete_elements {
    my ($self, $elements_arg) = @_;
    my (%del_data, %del_cont, $error);

    my $err_msg = 'Improper args to delete elements';

    for my $elem (@$elements_arg) {
        if (ref $elem eq 'HASH') {
            throw_gen(error => $err_msg)
              unless exists $elem->{id} && exists $elem->{type};

            if ($elem->{'type'} eq 'data') {
                $del_data{$elem->{'id'}} = undef;
            } elsif ($elem->{'type'} eq 'container') {
                $del_cont{$elem->{'id'}} = undef;
            } else {
                throw_gen(error => $err_msg);
            }
        } elsif (ref $elem) {
            if ($elem->is_container) {
                $del_cont{$elem->get_id} = undef;
            } else {
                $del_data{$elem->get_id} = undef;
            }
        } else {
            throw_gen(error => $err_msg);
        }
    }

    my $elements = $self->_get('_subelems');
    my $del_elements = $self->_get('_del_subelems') || [];

    my $order = 0;
    my $cont_order;
    my $data_order;
    my $new_list = [];
    my %delete_count;

    for my $elem (@$elements) {
        my $delete = undef;
        if ($elem->is_container) {
            if (exists $del_cont{$elem->get_id}) {
                my $elem_name = $elem->get_element_type->get_key_name;
                my $subelement_type = $self->get_element_type->get_containers($elem_name);

                # Increase the deletion counter
                $delete_count{$elem_name}++;

                # Get the minimum occurrence for this parent/child relation
                # Assume minimum occurrence of zero if child not present in parent type
                my $min_occur = 0;
                if ($subelement_type) {
                    $min_occur = $subelement_type->get_min_occurrence;
                }

                my $occur_diff = $self->get_elem_occurrence($elem_name) - $min_occur;

                # Check if we've deleted too many
                if ($delete_count{$elem_name} > $occur_diff) {
                    # Throw an error if we have
                    throw_invalid
                        error    => qq{Element "$elem_name" cannot be deleted. }
                                  . qq{There must be at least $min_occur elements of this type.},
                        maketext => [
                            'Element "[_1]" cannot be deleted. There must '
                          . 'be at least [quant,_2,element,elements] of this type.',
                            $elem_name,
                            $min_occur,
                        ]
                    ;
                } else {
                    # Schedule for deletion if we haven't
                    push @$del_elements, $elem;
                    $delete = 1;
                }
            }
        } else {
            if (exists $del_data{$elem->get_id}) {
                my $field_type = $elem->get_field_type;
                my $field_name = $field_type->get_key_name;

                # Increase the deletion counter
                $delete_count{$field_name}++;

                my $occur_diff = $self->get_field_occurrence($field_name) -
                        $field_type->get_min_occurrence;

                # Check if we've deleted too many
                if ($delete_count{$field_name} > $occur_diff) {
                    my $the_min_occur = $field_type->get_min_occurrence;
                    # Throw an error if we have
                    throw_invalid
                        error    => qq{Field "$field_name" cannot be deleted. }
                                  . qq{There must be at least $the_min_occur fields of this type.},
                        maketext => [
                            'Field "[_1]" cannot be deleted. There must '
                          . 'be at least [quant,_2,field,fields] of this type.',
                            $field_name,
                            $the_min_occur,
                        ]
                    ;
                } else {
                    # Schedule for deletion if we haven't
                    push @$del_elements, $elem;
                    $delete = 1;
                }
            }
        }

        unless ($delete) {
            my $count;
            $elem->set_place($order);
            if ($elem->is_container()) {
                if (exists $cont_order->{$elem->get_element_type_id }) {
                    $count = scalar @{ $cont_order->{$elem->get_element_type_id } };
                } else {
                    $count = 0;
                    $cont_order->{$elem->get_element_type_id } = [];
                }
                $elem->set_object_order($count);
            } else {
                if (exists $data_order->{ $elem->get_field_type_id }) {
                    $count = scalar
                      @{ $data_order->{$elem->get_field_type_id } };
                } else {
                    $count = 0;
                    $data_order->{$elem->get_field_type_id } = [];
                }
                $elem->set_object_order($count);
                push @{ $data_order->{$elem->get_field_type_id} },
                  $elem->get_id;
            }
            push @$new_list, $elem;
            $order++;
        }
    }

    return $self->_set(
        ['_subelems',  '_del_subelems'],
        [ $new_list,    $del_elements ]
    );
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

    $self->uncache_me;
    return $self->_set(['id'] => [undef]);
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
    my $elements = $self->get_elements();
    my ($at_count, $data_count) = ({},{});
    my @new_list;

    # make sure then number of elements passed is the same as what we have
    if (scalar @$elements != scalar @$new_order ) {
        throw_gen(error => 'Improper number of args to reorder_elements().');
    }

    # Order the elements in the order they are listed in $new_order
    foreach my $obj (@$new_order) {

        # Set this elements place among other elements.
        my $new_place = scalar @new_list;
        $obj->set_place($new_place)
          unless $obj->get_place == $new_place;
        push @new_list, $obj;

        # Get the appropriate element type ID and 'seen' hash.
        my ($at_id, $seen);
        if ($obj->is_container()) {
            $at_id = $obj->get_element_type_id;
            $seen  = $at_count;
        } else {
            $at_id = $obj->get_field_type_id;
            $seen  = $data_count;
        }

        # Set this elements place among other elements of its type.
        my $n = $seen->{$at_id} || 1;
        my $new_obj_order = $n++;
        $obj->set_object_order($new_obj_order)
          unless $obj->get_object_order == $new_obj_order;
        $seen->{$at_id} = $n;
    }

    $self->_set(['_subelems'] => [\@new_list]);
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

    my ($dirty, $id, $del) = $self->_get(qw(_dirty id _delete));
    if ($dirty) {
        if ($id) {
            return $self->_do_delete if $del;
            $self->_do_update;
        } else {
            $self->_do_insert;
        }
    }

    $self->_sync_elements;

    return $self->SUPER::save;
}

##############################################################################

=item my $pod = $container->serialize_to_pod;

=item my $pod = $container->serialize_to_pod($field_key_name);

Serializes the element and all of its subelements into the pseudo-pod format
parsable by C<update_from_pod()>. Pass in a field key name and those fields
will not have the POD tag, including in subelements that have the same field
key name. Subelements will begin with C<=begin $key_name> and end with C<=end
$key_name>, and will be indented four spaces relative to their parent
elements. Related stories and media will be identified by the tag specifed via
the C<RELATED_DOC_POD_TAG> F<bricolage.conf> directive or default to
C<=related_story_uuid> and C<=related_media_uuid> tags, respectively.

=cut

sub serialize_to_pod {
    my ($self, $default_field) = @_;
    $self->_podify($default_field, '');
}

##############################################################################

=item $container->update_from_pod($pod);

=item $container->update_from_pod($pod, $field_key_name);

Updates an element and all of its subelements from POD markup such as that
output by C<deserialize_pod()>. Any equal signs after two newlines that do
I<not> indicate a new field or element must be escaped with a slash. If
C<$field_key_name> is passed, then any blocks of text that do not have a POD
tag will be assumed to be instances of that field.

Subelements are supported using C<=begin key_name> and C<=end key_name> tags,
although the key namee in the C<=end> tag is optional. Subelements may be
indented, although the root element must not be indented. Indentation of a
subelement is deterimined by the amount of whitespace before the C<=begin>
tag. That whitespace will be trimmed from the beginning of all lines in the
subelement; any extra whitespace before lines will remain intact, enabling the
use of whitespace for formatting.

The contents of $pod will be split on C</\r?\n|\r/> to be parsed on a
line-by-line basis. The line endings will all be replaced with C<\n> only.

Any type of field may be specified in the POD. Dates, however, must be in
ISO-8601-compliant format ("YYYY-MM-DD hh:mm:ss") to be properly parsed.
Fields allowing only a limited number of values (such as pulldown or radio
fields) must have content corresponding to the available values. Fields that
allow multiple values (multiple select lists) are not supported.

Related media and related stories may be identified by using one of the
following tags as the first tags to appear in an element, either at the
beginning of the POD or just afer a subelement's C<=begin> tag:

=over

=item =related_story_uuid

=item =related_media_uuid

=item =related_story_uri

=item =related_media_uri

=item =related_story_id

=item =related_media_id

=item =related_story_url

=item =related_media_url

=back

For the last two options, the domain name will be extracted from the URL in
order to determine the site to search for the path section of the URL. For
example, specifying

  =related_story_url http://www.example.com/foo/bar/

will result in C<update_from_pod()> searchging for the URI "/foo/bar/"
associated with the site with the domain name "www.example.com".

B<Throws:>

=over

=item Bric::Util::Fault::Error::Invalid

=over

=item *

No context for content beginning at line [_1].

=item *

No such field "[_1]" at line [_2]. Did you mean "[_3]"?

=item *

No such subelement "[_1]" at line [_2]. Did you mean "[_3]"?

=item *

Non-repeatable field "[_1]" appears more than once beginning at line [_2].
Please remove all but one.

=item *

Unknown tag "[_1]" at line [_2].

=item *

No such site "[_1]" at line [_2].

=item *

No such URI "[_1]" in site "[_2]" at line [_3].

=item *

No story document found for UUID "[_1]" at line [_2].

=item *

No media document found for UUID "[_1]" at line [_2].

=item *

No story document found for ID "[_1]" at line [_2].

=item *

No media document found for ID "[_1]" at line [_2].

=item *

No story document found for URI "[_1]" at line [_2].

=item *

No media document found for URI "[_1]" at line [_2].

=back

=back

B<Side Effects:> Existing fields and subelements may be deleted or have their
values altered. New fields and subelements may be added.

B<Notes:> The values provided for fields allowing only a limited number of
values (such as pulldown or radio fields) are not currently enforced to be one
of those values.

=cut

sub update_from_pod {
    my ($self, $pod, $def_field) = @_;
    $def_field = '' unless defined $def_field;
    $self->_deserialize_pod([ split /\r?\n|\r/, $pod ], $def_field, '', 0);
    return $self;
}

################################################################################

=back

=head1 Private

=head2 Private Class Methods

=over 4

=item Bric::Biz::Element::Container->_do_list($class, $param, $ids)

Called by C<list()> or C<list_ids()>, this method returns either a list of ids
or a list of objects, depending on the third argument.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _do_list {
    my ($class, $params, $ids_only) = @_;

    my ($obj_type, @params);
    my @wheres = ('e.element_type__id = et.id');

    while (my ($k, $v) = each %$params) {
        if ($k eq 'object') {
            $obj_type = $v->key_name;
            push @wheres,
                any_where $v->get_version_id, 'e.object_instance_id = ?', \@params;
        }

        elsif ($k eq 'object_type') {
            $obj_type = $v;
        }

        elsif ($k eq 'id') {
            push @wheres, any_where $v, 'e.id = ?', \@params;
        }

        elsif ($k eq 'active' || $k eq 'displayed') {
            push @wheres, "e.$k = ?";
            push @params, $v ? 1 : 0;
        }

        elsif ($k eq 'parent_id') {
            push @wheres, defined $v
                ? any_where($v, 'e.parent_id = ?', \@params)
                : 'e.parent_id IS NULL';
        }

        elsif ($k eq 'element_type_id' || $k eq 'element_id') {
            push @wheres, any_where $v, 'e.element_type__id = ?', \@params;
        }

        elsif ($k eq 'related_media_id' || $k eq 'related_story_id') {
            ( my $col = $k ) =~ s/_id$/__id/;
            push @wheres, defined $v
                ? any_where($v, "e.$col = ?", \@params)
                : "e.$col IS NULL";
        }

        elsif ($k eq 'key_name' || $k eq 'name' || $k eq 'description') {
            push @wheres, any_where $v, "LOWER(et.$k) LIKE LOWER(?)", \@params;
        }
    }

    throw_gen 'Missing required parameter "object" or "object_type"'
        unless $obj_type;

    my $tables = "$obj_type\_element e, element_type et";

    my ($qry_cols, $order) = $ids_only
        ? ('DISTINCT e.id', 'e.id')
        : (join(', ', @SEL_COLS), 'e.object_instance_id, e.place');
    my $wheres = @wheres ? 'WHERE  ' . join(' AND ', @wheres) : '';

    my $sel = prepare_c(qq{
        SELECT $qry_cols
        FROM   $tables
        $wheres
        ORDER BY $order
    }, undef, DEBUG);

    # Just return the IDs, if they're what's wanted.
    if ($ids_only) {
        my $ids = col_aref($sel, @params);
        return wantarray ? @$ids : $ids;
    }

    my @objs;
    execute($sel, @params);
    my @d;
    bind_columns( $sel, \@d[ 0..$#SEL_COLS ] );
    while ( fetch($sel) ) {
        my $self = $class->SUPER::new;
        $self->_set( [ 'object_type', @SEL_FIELDS ] => [$obj_type, @d] );
        $self->_set__dirty(0);
        push @objs, $self->cache_me;
    }
    return wantarray ? @objs : \@objs;
}

################################################################################

=back

=begin private

=head2 Private Instance Methods

=over 4

=item $container->_do_delete

Called by C<save()>, this method deletes the container element from the
database.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _do_delete {
    my $self = shift;

    my ($id, $type) = $self->_get(qw(id object_type));
    my $table = "$type\_element";
    my $sth = prepare_c(qq{
        DELETE FROM $table
        WHERE  id = ?
    }, undef);

    execute($sth, $id);
    return $self;
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
    my $self = shift;

    my $table = $self->get_object_type . '_element';

    my $value_cols = join ', ', ('?') x @COLS;
    my $ins_cols   = join ', ', @COLS;

    my $ins = prepare_c(qq{
        INSERT INTO $table ($ins_cols)
        VALUES ($value_cols)
    }, undef);
    execute($ins, $self->_get(@FIELDS) );

    return $self->_set( ['id'] => [last_key($table)] );
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
    my $self = shift;

    my $table    = $self->get_object_type . '_element';
    my $set_cols = join ' = ?, ', @COLS;

    my $upd = prepare_c(qq{
        UPDATE $table
        SET    $set_cols = ?
        WHERE  id = ?
    }, undef);

    execute($upd, $self->_get(@FIELDS, 'id'));
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
    my $self = shift;
    my ($id, $inst_id, $elements, $del_elements)
        = $self->_get(qw(id object_instance_id _subelems _del_subelems));

    for my $elem (@$elements) {
        # Set the parent ID and object instance ID and save.
        my $pid = $elem->get_parent_id;
        $elem->set_parent_id($id) unless defined $pid && $pid == $id;
        my $old_iid = $elem->get_object_instance_id;
        $elem->set_object_instance_id($inst_id)
            unless defined $old_iid && $old_iid == $inst_id;
        $elem->save;
    }

    while (my $t = shift @$del_elements) {
        next unless $t->get_id;
        $t->set_object_order(0);
        $t->set_place(0);
        $t->deactivate->save;
    }

    return $self;
}

##############################################################################

=item my $pod = $element->_podify($default_field, $indent);

This recursive method is called by C<serialize_to_pod()> and does all of the
work of serializing an element and all of its subelements to the pseudo-pod
format parsable by C<update_from_pod()>. The C<$default_field> argument is the
optionaly default field, while C<$indent> contains the whitespace
corresponding to the indentation level of the current element. C<_podify()> is
called recursively for subelements in order to build up a complete
representation of the element and its subelements as POD. Each subelement is
indented another four spaces relative to its parent by incremented C<$indent>
by that string for each recursion.

=cut

sub _podify {
    my ($self, $default_field, $indent) = @_;
    my $pod = '';
    $default_field = '' unless defined $default_field;

    # Start with related story.
    if (my $rel_story = $self->get_related_story) {
        $pod .= "$indent=related_story_" . RELATED_DOC_POD_TAG . q{ }
              . _rel_link($rel_story) . "\n\n";
    }

    # Add related media.
    if (my $rel_media = $self->get_related_media) {
        $pod .= "$indent=related_media_" . RELATED_DOC_POD_TAG . q{ }
              . _rel_link($rel_media) . "\n\n";
    }

    # Dump all of the fields and subelements.
    for my $sub ($self->get_elements) {
        if ($sub->is_container) {
            my $kn = $sub->get_key_name;
            $pod .= "$indent=begin $kn\n\n"
                 .  $sub->_podify($default_field, $indent . ' ' x 4)
                 .  "$indent=end $kn\n\n";
        } else {
            my $kn = $sub->get_key_name;
            my $wt = $sub->get_widget_type;

            (my $data = $sub->get_value) =~ s/((?:^|\r?\n|\r)+\s*)=/$1\\=/g;
            if ($wt eq 'checkbox') {
                $data = $data ? '1' : '0';
            }

            $pod .= "$indent=$kn\n\n" unless $kn eq $default_field;
            $data =~ s/(\r?\n|\r)(?!$)/$1$indent/mg if $indent;
            $pod .= "$indent$data\n\n";
        }
    }
    return $pod;
}

##############################################################################

=item $element = $element->_deserialize_pod(\@pod, $def_field, $indent, $line_num)

This recursive method is called by C<update_from_pod()> and does all the work
of parsing lines of POD. The arguments are:

=over

=item 1 \@pod

An array reference of lines of POD corresponding to the current element
any subelements.

=item 2 $def_field

The key name of the default field, if any. If provided, any blockes of content
lacking a POD tag will be assumed to be instances of this field.

=item 3 $indent

The indentation level of the current element. C<update_from_pod()> assumes
that the top-level element begins with no indentation level. The indentation
level of subelements is determined by the whitespace preceding their C<=begin>
tags. This whitespace will be trimmed from the beginning of all lines of the
element.

=item 4 $line_num

The file line number of the line preceeding line in C<\@pod>.
C<update_from_pod> starts it off at line 0, and recursive calls pass it
appropriately to keep track of all line numbers. These line numbers are used
in exception messages.

=back

=cut

sub _deserialize_pod {
    my ($self, $pod, $def_field, $indent, $line_num) = @_;

    # Get the element type and other basics for this element.
    my $elem_type    = $self->get_element_type;
    my $elem_type_id = $self->get_element_type_id;
    my $doc_type     = $self->get_object_type;
    my $doc_id       = $self->get_object_instance_id;
    my $id           = $self->get_id;
    $self->_set([qw(related_story_id related_media_id)] => [undef, undef]);

    # Identify the allowed subelements and fields.
    my %elem_types  = map { $_->get_key_name => $_ }
        $elem_type->get_containers;
    my %field_types = map { $_->get_key_name => $_ }
        $elem_type->get_field_types;

    # Gather up the existing elements and fields.
    my (%elems_for, %fields_for);
    for my $e ($self->get_elements) {
        my $subelems_for = $e->is_container ? \%elems_for
                                            : \%fields_for
                                            ;

        # Even if it's no longer a valid element, it can still be edited.
        push @{$subelems_for->{$e->get_key_name}}, $e;
    }

    # Get ready!
    my (@elems, %elem_ord, %field_ord);

    POD:
    while (@$pod) {
        my $line = shift @$pod;
        $line_num++;
        # Each line can be either blank, contain content, contain an over tag,
        # Or contain a field tag.

        # Start with POD commands.
        if ($line =~ /^\s*=(\S+)\s+(\S+)\s*$/) {
            my ($tag, $kn) = ($1, $2);

            if ($tag eq 'begin') {
                unless ($elem_types{$kn} || $elems_for{$kn}) {
                    my $try = _find_closest_word($kn, keys %elem_types);
                    throw_invalid
                        error    => qq{No such subelement "$kn" at line }
                                  . qq{$line_num. Did you mean "$try"?},
                        maketext => [
                            'No such subelement "[_1]" at line [_2]. Did you mean '
                            . '"[_3]"?',
                            $kn,
                            $line_num,
                            $try
                        ]
                    ;
                }

                shift @$pod; # Assume next line is blank.
                $line_num++;

                # Collect all of the contents of the elements and its subelements.
                my $count = 1;
                my @subpod;
                SUBELEM:
                while (@$pod) {
                    # Don't increment line num; subelement will do so.
                    $line = shift @$pod;
                    if ($line =~ /^\s*=begin/) {
                        $count++;
                    } elsif ($line =~ /^\s*=end/) {
                        unless (--$count) {
                            shift @$pod; # Skip empty line.
                            $line_num++;
                            last SUBELEM;
                        }
                    }
                    push @subpod, $line;
                }

                # Grab the element and populate its contents.
                my $subelem = $elems_for{$kn} && @{$elems_for{$kn}}
                    ? shift @{$elems_for{$kn}}
                        : __PACKAGE__->new({
                            active             => 1,
                            object_type        => $doc_type,
                            object_instance_id => $doc_id,
                            element_type       => $elem_types{$kn},
                            parent_id          => $id,
                        });

                # Check for element occurrence violation
                my $subelem_key_name = $subelem->get_key_name;
                my $elem_key_name = $self->get_key_name;
                my $subelem_occur = $self->get_elem_occurrence($subelem_key_name);
                my @subets = $self->get_element_type->get_containers($subelem_key_name);

                # Throw an error if $subets[0] doesn't exist
                if (!($subets[0])) {
                    throw_invalid
                        error    => qq{$subelem_key_name cannot a subelement }
                                  . qq{of $elem_key_name.},
                        maketext => [ '[_1] cannot be a subelement of [_2].',
                            $subelem_key_name,
                            $elem_key_name,
                        ]
                    ;
                }

                my $subelem_max = $subets[0]->get_max_occurrence;

                if ($subelem_max && ($subelem_max >= $subelem_occur)) {
                    # Throw an error
                    throw_invalid
                        error    => qq{Element "$elem_key_name" cannot be added. There are already }
                                  . qq{$subelem_occur elements of this type, with a max of $subelem_max.},
                        maketext => [
                          'Element "[_1]" cannot be added. There are already '
                        . '[quant,_2,element,elements] of this type, with a max of [_3].',
                            $elem_key_name,
                            $subelem_occur,
                            $subelem_max,
                        ]
                    ;
                }

                $subelem->set_place(scalar @elems);
                $subelem->set_object_order(++$elem_ord{$kn});
                push @elems, $subelem;

                (my $subindent = $subpod[0]) =~ s/^(\s*).*/$1/;
                $line_num = $subelem->_deserialize_pod(
                    \@subpod,
                    $def_field,
                    ($subindent || ''),
                    $line_num,
                );
                next POD;
            }

            # Try relateds.
            elsif ($tag =~ /related_(story|media)_(id|uuid|uri|url)/) {
                my $type       = $1;
                my $class      = 'Bric::Biz::Asset::Business::'. ucfirst $type;
                my $attr       = $2;
                my $doc_id;
                my $meth       = "is_related_$type";
                my $rel_attr   = "related_$type\_id";

                throw_invalid
                    error => 'Element "' . $self->get_key_name
                           . qq{" cannot have a related $type.},
                    maketext => [
                        qq{Element "[_1]" cannot have a related $type.},
                        $self->get_key_name
                    ]
                    unless $self->get_element_type->$meth;

                # Handle full URL first.
                if ($attr eq 'url') {
                    # Figure out the site.
                    my $full_uri = URI->new($kn);
                    my $domain_name = $full_uri->host;
                    my $uri = $full_uri->path;
                    my ($site_id) = Bric::Biz::Site->list_ids({
                        domain_name => $domain_name
                    }) or throw_invalid
                            error    => qq{No such site "$domain_name" at }
                                     .  "line $line_num.",
                            maketext => [
                                'No such site "[_1]" at line [_2].',
                                $domain_name,
                                $line_num,
                            ]
                        ;
                    ($doc_id) = $class->list_ids({
                        site_id => $site_id,
                        uri     => $uri,
                    }) or throw_invalid
                        error => qq{No such URI "$uri" in site "$domain_name" }
                               . "at line $line_num.",
                        maketext => [
                            'No such URI "[_1]" in site "[_2]" at line [_3].',
                            $uri,
                            $domain_name,
                            $line_num,
                        ]
                    ;
                }

                # We can just look up the doc.
                else {
                    # XXX Restrict site when searching on URI?
                    ($doc_id) = $class->list_ids({ $attr => $kn })
                        or throw_invalid
                            error     => qq{No $type document found for \U$attr\E "$kn" }
                                      .  "at line $line_num.",
                            maketext => [
                                qq{No $type document found for \U$attr\E "[_1]" at line [_2].},
                                $kn,
                                $line_num,
                            ]
                        ;
                }

                # Make the association.
                $self->_set([$rel_attr] => [$doc_id]);
            }

            # Bad tag.
            else {
                throw_invalid
                    error    => qq{Unknown tag "$line" at line $line_num.},
                    maketext => [
                        'Unknown tag "[_1]" at line [_2].',
                        $line,
                        $line_num,
                    ]
                ;
            }

            shift @$pod; # Skip empty line.
            $line_num++;
            next POD;
        }

        # Otherwise, it's either a tagged field or a default field.
        else {
            my ($kn, $content, $field_type);
            if ($line =~ /^\s*=(\S+)\s*$/) {
                $kn = $1;
                $field_type = $field_types{$kn};
                unless ($field_type) {
                    _bad_field(\%field_types, $kn, $line_num)
                        unless $fields_for{$kn} && @{$fields_for{$kn}};
                    $field_type = shift( @{$fields_for{$kn}} )->get_field_type;
                }

                # Make sure that it's okay if it's repeatable.
                my $field_occurrence = $self->get_field_occurrence($field_type->get_key_name);
                my $max_occur = $field_type->get_max_occurrence;
                if ($field_ord{$kn} && $max_occur && $field_occurrence >= $max_occur) {
                    throw_invalid
                        error    => qq{Field "$kn" appears $field_occurrence }
                                  . qq{times around line $line_num.}
                                  . qq{Please remove all but $max_occur.},
                        maketext => [
                            'Field "[_1]" appears [_2] times around line [_3]. '
                          . 'Please remove all but [_4].',
                            $kn,
                            $field_occurrence,
                            $line_num,
                            $max_occur,
                        ]
                    ;
                }

                shift @$pod; # Throw out empty line.
                $line_num++;

                $content = '';

                # Gather up the contents of the field.
                FIELD:
                while (@$pod) {
                    $line = shift @$pod;
                    $line_num++;

                    # If the line is empty, check the next two lines.
                    if ($line =~ /^\s*$/) {
                        # If the next line is another tag, we have this field.
                        last FIELD
                            if @$pod && ($pod->[0] =~ /^\s*=/ || $def_field ne '');

                        # Otherwise, just keep the line.
                        ($content .= "$line\n") =~ s/^$indent//mg;
                    }

                    # Otherwise, the line has either content or a pod tag.
                    else {
                        if ($line =~ /^\s*=/) {
                            unshift @$pod, $line;
                            --$line_num;
                            last FIELD;
                        }
                        ($content .= "$line\n") =~ s/^$indent//mg;
                    }
                }
            }

            else {
                $kn = $def_field;
                $field_type = $field_types{$kn};

                # we weren't expecting this default field *here*,
                # so just ignore it
                if (not defined $field_type) {
                    next POD;
                }
                my $field_occurrence = $self->get_field_occurrence($field_type->get_key_name);
                my $max_occur = $field_type->get_max_occurrence;
                if (defined $field_type && $field_ord{$kn} && $max_occur && $field_occurrence > $max_occur) {
                    throw_invalid
                        error    => qq{Field "$kn" appears $field_occurrence }
                                  . qq{times around line $line_num.}
                                  . qq{Please remove all but $max_occur.},
                        maketext => [
                            'Field "[_1]" appears [_2] times around line [_3].'
                          . 'Please remove all but [_4].',
                            $kn,
                            $field_occurrence,
                            $line_num,
                            $max_occur,
                        ]
                    ;
                }

                ($content .= "$line\n") =~ s/^$indent//mg;
                DEF_FIELD:
                while (@$pod) {
                    $line = shift @$pod;
                    $line_num++;
                    last DEF_FIELD if $line =~ /^\s*$/;
                    ($content .= "$line\n") =~ s/^$indent//mg;
                }
            }

            # Fix up the content.
            if ($field_type->get_sql_type eq 'date') {
                # Eliminate white space to set date.
                $content =~ s/^\s+//;
                $content =~ s/\s+$//;
            } elsif (@$pod) {
                # Strip off trailing newline added by the parser.
                $content =~ s/\n$//m;
            } else {
                # Strip off trailing newlines added by the parser.
                $content =~ s/\n{1,2}$//m;
            }

            # Add the field.
            my $field = $fields_for{$kn} && @{$fields_for{$kn}}
                ? shift @{$fields_for{$kn}}
                : Bric::Biz::Element::Field->new({
                    active             => 1,
                    object_type        => $doc_type,
                    object_instance_id => $doc_id,
                    field_type         => $field_type,
                });
            $field->set_value($content) if defined $content;
            $field->set_place(scalar @elems);
            $field->set_object_order(++$field_ord{$kn});
            push @elems, $field;
            next POD;
        }
    }

    # Delete any remaining fields and containers.
    my $del_elems = $self->_get('_del_subelems') || [];
    push @$del_elems, @{$fields_for{$_}} for keys %fields_for;
    push @$del_elems, @{$elems_for{$_}}  for keys %elems_for;

    # Make it so.
    $self->_set(
        [qw(_subelems _del_subelems)],
        [   \@elems,  $del_elems    ]
    );

    return $line_num;
}

##############################################################################

=back

=head2 Private Functions

=over

=item my $closest = _find_closest_word($word, @alt_words);

This function returns the word from @alt_words that is closest to $word.
"Closeness" is determinted by C<Text::LeventshteinXS::distance()>.

=cut

sub _find_closest_word {
    my $word  = shift;
    my @score = map { distance( $word, $_ ) } @_;
    my $best  = reduce { $score[ $a ] < $score[ $b ] ? $a : $b } 0 .. $#_;
    return $_[ $best ];
}

=over

=item _bad_field($field_types, $key_name, $line_num)

This function is called by _deserialize_pod() whenever it encounters an
invalid field key name, or a missing key name, or the default key name is
invalid. It throws the appropriate exception and makes suggestions as
necessary.

=cut

sub _bad_field {
    my ($field_types, $key_name, $line_num) = @_;

    # Throw an exception if there is no default field key name.
    throw_invalid
        error    => "No context for content beginning at line $line_num.",
        maketext => [
            'No context for content beginning at line [_1].',
            $line_num,
        ] unless defined $key_name && $key_name ne '';

    # Suggest an alternative default field.
    my $try =_find_closest_word($key_name, keys %$field_types);
    throw_invalid
        error    => qq{No such field "$key_name" at line $line_num. }
                  . qq{Did you mean "$try"?},
        maketext => [
            'No such field "[_1]" at line [_2]. Did you mean "[_3]"?',
            $key_name,
            $line_num,
            $try,
        ];
}

################################################################################

=item my $link = _rel_link($document)

Returns a string for a related link for $document relative to the settinf of
the C<RELATED_DOC_POD_TAG> F<bricolage.conf> directive.

=cut

sub _rel_link {
    my $doc = shift;
    return RELATED_DOC_POD_TAG eq 'uuid' ? $doc->get_uuid
         : RELATED_DOC_POD_TAG eq 'uri'  ? $doc->get_primary_uri
         : RELATED_DOC_POD_TAG eq 'id'   ? $doc->get_id
         : do {
             my $site  = Bric::Biz::Site->lookup({ id => $doc->get_site_id });
             my $proto = 'http';
             if (my $oc = $doc->get_primary_oc) {
                 if ($proto = $oc->get_protocol) {
                     $proto =~ s{[/:]+}{}g;
                 }
             }
             my $uri  = URI->new($doc->get_primary_uri);
             $uri->scheme($proto);
             $uri->host($site->get_domain_name);
             $uri->as_string;
         };
}

1;
__END__

=back

=end private

=head1 Notes

NONE

=head1 Authors

Michael Soderstrom <miraso@pacbell.net>

Refactoring and POD serialization and parsing by David Wheeler
<david@kineticode.com>

=head1 See Also

L<perl>, L<Bric>, L<Bric::Biz::Asset>, L<Bric::Biz::Asset::Business>,
L<Bric::Biz::Element>

=cut
