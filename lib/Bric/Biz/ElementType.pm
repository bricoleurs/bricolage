package Bric::Biz::ElementType;

###############################################################################

=head1 Name

Bric::Biz::ElementType - Bricolage element types

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

  # Create new types of elements.
  $element = Bric::Biz::ElementType->new($init)
  $element = Bric::Biz::ElementType->lookup({id => $id})
  ($at_list || @ats) = Bric::Biz::ElementType->list($param)
  ($id_list || @ids) = Bric::Biz::ElementType->list_ids($param)

  # Return the ID of this object.
  $id = $element->get_id()

  # Get/set this element type's name.
  $element = $element->set_name( $name )
  $name       = $element->get_name()

  # Get/set the description for this element type
  $element  = $element->set_description($description)
  $description = $element->get_description()

  # Get/set the primary output channel ID for this element type.
  $element = $element->set_primary_oc_id($oc_id, $site_id);
  $oc_id = $element->get_primary_oc_id($site_id);

  # Attribute methods.
  $val  = $element->set_attr($name, $value);
  $val  = $element->get_attr($name);
  \%val = $element->all_attr;

  # Attribute metadata methods.
  $val = $element->set_meta($name, $meta, $value);
  $val = $element->get_meta($name, $meta);

  # Manage output channels.
  $element        = $element->add_output_channels([$output_channel])
  ($oc_list || @ocs) = $element->get_output_channels()
  $element        = $element->delete_output_channels([$output_channel])

  # Manage sites
  $element               = $element->add_sites([$site])
  ($site_list || @sites) = $element->get_sites()
  $element               = $element->remove_sites([$site])

  # Manage the parts of an element type.
  $element            = $element->add_field_types($field);
  $field_type         = $element->new_field_type($param);
  $element            = $element->copy_field_type($at, $field);
  ($part_list || @parts) = $element->get_field_types($field);
  $element            = $element->del_field_types($field);

  # Add, retrieve and delete containers from this element type.
  $element            = $element->add_containers($at || [$at]);
  (@at_list || $at_list) = $element->get_containers();
  $element            = $element->del_containers($at || [$at]);

  # Get/set the active flag.
  $element  = $element->activate()
  $element  = $element->deactivate()
  (undef || 1) = $element->is_active()

  # Save this element type.
  $element = $element->save()

=head1 Description

The element type class registers new type of elements that define the
structures of story and media documents. Element type objects are composed of
subelement types and fields, and top-level (story and media type) element
types are associated with sites and output channels to define how documents
based on them will be output and in what sites they can be created.

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
use Bric::Util::Fault qw(throw_gen throw_dp);
use Bric::Util::Grp::ElementType;
use Bric::Biz::ElementType::Parts::FieldType;
use Bric::Util::Attribute::ElementType;
use Bric::Util::Class;
use Bric::Biz::Site;
use Bric::Biz::OutputChannel::Element;
use Bric::Util::Coll::OCElement;
require Bric::Util::Coll::Subelement;
use Bric::Util::Coll::Site;
use Bric::App::Cache;
use List::Util qw(first);

#==============================================================================#
# Inheritance                          #
#======================================#

use base qw( Bric Exporter );

#=============================================================================#
# Function Prototypes                  #
#======================================#
my ($get_oc_coll, $get_site_coll, $get_sub_coll, $remove, $make_key_name);

#==============================================================================#
# Constants                            #
#======================================#

use constant DEBUG             => 0;
use constant HAS_MULTISITE     => 1;
use constant GROUP_PACKAGE     => 'Bric::Util::Grp::ElementType';
use constant INSTANCE_GROUP_ID => 27;
use constant STORY_CLASS_ID    => 10;

use constant ORD => qw(
    name
    key_name
    description
    top_level
    paginated
    fixed_uri
    related_story
    related_media
    media
    displayed
    biz_class_id
    active
);

#==============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields
our $METHS;
our @EXPORT_OK   = @Bric::Biz::OutputChannel::EXPORT_OK;
our %EXPORT_TAGS = %Bric::Biz::OutputChannel::EXPORT_TAGS;

#--------------------------------------#
# Private Class Fields
my $table = 'element_type';
my $mem_table = 'member';
my $map_table = $table . "_$mem_table";

my @cols = qw(
    name
    key_name
    description
    top_level
    paginated
    fixed_uri
    related_story
    related_media
    media
    displayed
    biz_class__id
    type__id
    active
);

my @props = qw(
    name
    key_name
    description
    top_level
    paginated
    fixed_uri
    related_story
    related_media
    media
    displayed
    biz_class_id
    type_id
    _active
);

my $sel_cols = join ', ', 'a.id', map({ "a.$_" } @cols), 'm.grp__id';
my @sel_props = ('id', @props, 'grp_ids');

my %bool_attrs = map { $_ => undef } qw(
    top_level
    paginated
    fixed_uri
    related_story
    related_media
    displayed
    media
    active
);

# Needed from the subelement
my $SEL_TABLES = "$table a, $mem_table m, $map_table etm";
my $SEL_WHERES = "a.id = etm.object_id AND etm.member__id = m.id " .
    "AND m.active = '1'";
my $SEL_ORDER = "a.name, a.id";
my $GRP_ID_IDX = $#sel_props;

# The subclass *must* be loaded after the above scalars are set so that it can
# access their values via the below methods. C'est la vie.
require Bric::Biz::ElementType::Subelement;

# These are provided for the ElementType::Subelement subclass to take
# advantage of.
sub SEL_PROPS  { @sel_props }
sub SEL_COLS   { $sel_cols }
sub SEL_TABLES { $SEL_TABLES }
sub SEL_WHERES { $SEL_WHERES }
sub SEL_ORDER  { $SEL_ORDER }
sub GRP_ID_IDX { $GRP_ID_IDX }

#--------------------------------------#
# Instance Fields

BEGIN {
    Bric::register_fields({
        id                  => Bric::FIELD_READ,
        key_name            => Bric::FIELD_RDWR,
        name                => Bric::FIELD_RDWR,
        description         => Bric::FIELD_RDWR,
        burner              => Bric::FIELD_RDWR, # Deprecated
        top_level           => Bric::FIELD_NONE,
        paginated           => Bric::FIELD_NONE,
        fixed_uri           => Bric::FIELD_NONE,
        related_story       => Bric::FIELD_NONE,
        related_media       => Bric::FIELD_NONE,
        media               => Bric::FIELD_NONE,
        displayed           => Bric::FIELD_RDWR,
        biz_class_id        => Bric::FIELD_RDWR,
        type_id             => Bric::FIELD_READ,
        grp_ids             => Bric::FIELD_READ,

        _site_primary_oc_id => Bric::FIELD_NONE,
        _active             => Bric::FIELD_NONE,
        _oc_coll            => Bric::FIELD_NONE,
        _site_coll          => Bric::FIELD_NONE,
        _sub_coll           => Bric::FIELD_NONE,
        _parts              => Bric::FIELD_NONE,
        _new_parts          => Bric::FIELD_NONE,
        _del_parts          => Bric::FIELD_NONE,
        _attr               => Bric::FIELD_NONE,
        _meta               => Bric::FIELD_NONE,
        _attr_obj           => Bric::FIELD_NONE,
        _att_obj            => Bric::FIELD_NONE,
    });
}

#==============================================================================#
# Interface Methods                    #
#======================================#

=head1 Interface

=head2 Constructors

=over 4

=item $element = Bric::Biz::ElementType->new($init)

Will return a new element type object with the optional initial state

Supported Keys:

=over 4

=item name

=item key_name

=item description

=item top_level

Defaults to false.

=item paginated

Defaults to false.

=item fixed_uri

Defaults to false.

=item related_story

Defaults to false.

=item related_media

Defaults to false.

=item media

Defaults to false.

=item displayed

Defaults to false.

=item biz_class_id

Defaults to the ID for Bric::Biz::Asset::Business::Story.

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub new {
    my ($class, $init) = @_;
    $init->{_active} = 1;
    # Backwards compatibility for Bric::Biz::ATType.
    if (my $type_id = $init->{type_id} ||= delete $init->{type__id}) {
        my @bool_attrs = grep { $_ ne 'displayed' } keys %bool_attrs;
        if (my $type = Bric::Biz::ATType->lookup({ id => $type_id })) {
            @{$init}{@bool_attrs, 'biz_class_id', 'fixed_uri'}
                = $type->_get(@bool_attrs, 'biz_class_id', 'fixed_url');
        } else {
            delete $init->{type_id};
        }
        # Displayed not suported by ATType.
        $init->{displayed} ||= 0;
    } else {
        # Set up boolean defaults.
        for my $attr (keys %bool_attrs) {
            $init->{$attr} = $init->{$attr} ? 1 : 0;
        }
        # Set up default business class ID.
        $init->{biz_class_id} ||= STORY_CLASS_ID;
    }

    # Set the instance group ID.
    push @{$init->{grp_ids}}, INSTANCE_GROUP_ID;

    my $self = $class->SUPER::new($init);
    my $pkg = $self->get_biz_class;

    # If a package was passed in then find the autopopulated field names.
    my $i = 0;
    if ($pkg && UNIVERSAL::isa($pkg, 'Bric::Biz::Asset::Business::Media')) {
        foreach my $name ($pkg->autopopulated_fields) {
            my $key_name = lc $name;
            $key_name =~ y/a-z0-9/_/cs;
            my $atd = $self->new_field_type({
                key_name      => $key_name,
                name          => $name,
                description   => "Autopopulated $name field.",
                min_occurrence => 1,
                sql_type      => 'short',
                autopopulated => 1,
                widget_type   => 'text',
                length        => 32,
                place         => ++$i,
                max_occurrence => 1,
            });
        }
    }

    # Set the dirty bit for this new object.
    $self->_set__dirty(1);

    return $self;
}

##############################################################################

=item $element = Bric::Biz::ElementType->lookup({id => $id})

=item $element = Bric::Biz::ElementType->lookup({key_name => $key_name})

Looks up and instantiates a new Bric::Biz::ElementType object based on the
Bric::Biz::ElementType object ID or name passed. If C<$id> or C<$key_name> is not
found in the database, C<lookup()> returns C<undef>.

B<Throws:>

=over 4

=item *

Too many Bric::Biz::ElementType objects found.

=back

B<Side Effects:> NONE

B<Notes:> NONE

=cut

sub lookup {
    my $pkg = shift;
    my $elem = $pkg->cache_lookup(@_);
    return $elem if $elem;

    $elem = $pkg->_do_list(@_);
    # We want @$cat to have only one value.
    throw_dp(error => 'Too many ' . __PACKAGE__ . ' objects found.')
      if @$elem > 1;
    return @$elem ? $elem->[0] : undef;
}

##############################################################################

=item ($at_list || @at_list) = Bric::Biz::ElementType->list($param);

This will return a list of objects that match the criteria defined.

Supported Keys:

=over 4

=item id

Element ID. May use C<ANY> for a list of possible values.

=item name

The name of the element type. Matched with case-insentive LIKE. May use C<ANY>
for a list of possible values.

=item key_name

The unique key name of the element type. Matched with case insensitive LIKE. May
use C<ANY> for a list of possible values.

=item description

The description of the element type. Matched with case-insentive LIKE. May use
C<ANY> for a list of possible values.

=item output_channel_id

The ID of an output channel. Returned will be all ElementType objects that
contain this output channel. May use C<ANY> for a list of possible values.

=item field_name

=item data_name

The name of an ElementType::Parts::FieldType (field type) object. Returned will be
all ElementType objects that reference this particular field type object. May
use C<ANY> for a list of possible values.

=item active

Boolean value for active or inactive element types.

=item type_id

Match elements of a particular attype. May use C<ANY> for a list of possible
values.

=item site_id

Match against the given site_id. May use C<ANY> for a list of possible values.

=item top_level

Boolean value for top-level (story type and media type) element types.

=item media

Boolean value for media element types.

=item paginated

Boolean value for paginated element types.

=item fixed_uri

Boolean value for fixed URI element types.

=item displayed

Boolean value for displayed element types.

=item related_story

Boolean value for related story element types.

=item related_media

Boolean value for related media element types.

=item biz_class_id

The ID of a Bric::Util::Class object representing a business class. The ID
must be for a class object representing one of
L<Bric::Biz::Asset::Business::Story|Bric::Biz::Asset::Business::Story>,
L<Bric::Biz::Asset::Business::Media|Bric::Biz::Asset::Business::Media>, or one
of its subclasses. May use C<ANY> for a list of possible values.

=item child_id

ElementType id for children with the specified id.

=item parent_id

ElementType id for parents with the specified id

=back

B<Throws:>

=over 4

=item Exception::DA

=back

=cut

sub list { _do_list(@_) }

##############################################################################

=item ($at_list || @ats) = Bric::Biz::ElementType->list_ids($param)

This will return a list of objects that match the criteria defined. See the
C<list()> method for the allowed keys of the C<$param> hash reference.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub list_ids { _do_list(@_, 1) }

##############################################################################

=back

=head2 Destructors

=over 4

=item $self->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

=cut

sub DESTROY {
    # This method should be here even if its empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

##############################################################################

=back

=head2 Public Class Methods

=over 4

=item $meths = Bric::Biz::ElementType->my_meths

=item (@meths || $meths_aref) = Bric::Biz::ElementType->my_meths(TRUE)

=item my (@meths || $meths_aref) = Bric::Biz::ElementType->my_meths(0, TRUE)

Returns an anonymous hash of introspection data for this object. If called
with a true argument, it will return an ordered list or anonymous array of
introspection data. If a second true argument is passed instead of a first,
then a list or anonymous array of introspection data will be returned for
properties that uniquely identify an object (excluding C<id>, which is
assumed).

Each hash key is the name of a property or attribute of the object. The value
for a hash key is another anonymous hash containing the following keys:

=over 4

=item name

The name of the property or attribute. Is the same as the hash key when an
anonymous hash is returned.

=item disp

The display name of the property or attribute.

=item get_meth

A reference to the method that will retrieve the value of the property or
attribute.

=item get_args

An anonymous array of arguments to pass to a call to get_meth in order to
retrieve the value of the property or attribute.

=item set_meth

A reference to the method that will set the value of the property or
attribute.

=item set_args

An anonymous array of arguments to pass to a call to set_meth in order to set
the value of the property or attribute.

=item type

The type of value the property or attribute contains. There are only three
types:

=over 4

=item short

=item date

=item blob

=back

=item len

If the value is a 'short' value, this hash key contains the length of the
field.

=item search

The property is searchable via the list() and list_ids() methods.

=item req

The property or attribute is required.

=item props

An anonymous hash of properties used to display the property or
attribute. Possible keys include:

=over 4

=item type

The display field type. Possible values are

=over 4

=item text

=item textarea

=item password

=item hidden

=item radio

=item checkbox

=item select

=back

=item length

The Length, in letters, to display a text or password field.

=item maxlength

The maximum length of the property or value - usually defined by the SQL DDL.

=back

=item rows

The number of rows to format in a textarea field.

=item cols

The number of columns to format in a textarea field.

=item vals

An anonymous hash of key/value pairs reprsenting the values and display names
to use in a select list.

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

my ($tmpl_archs, $sel);

sub my_meths {
    my ($pkg, $ord, $ident) = @_;

    unless ($sel) {
        my $classes = Bric::Util::Class->pkg_href;
        while (my ($k, $v) = each %$classes) {
            next unless $k =~ /^bric::biz::asset::business::/;
            my $d = [ $v->get_id, $v->get_disp_name ];
            $d->[1] = 'Other Media' if $v->get_key_name eq 'media';
            push @$sel, $d;
        }
    }

    # Create 'em if we haven't got 'em.
    $METHS ||= {
        name => {
            name     => 'name',
            get_meth => sub { shift->get_name(@_) },
            get_args => [],
            set_meth => sub { shift->set_name(@_) },
            set_args => [],
            disp     => 'Name',
            search   => 1,
            len      => 64,
            req      => 1,
            type     => 'short',
            props    => {
                type      => 'text',
                length    => 32,
                maxlength => 64
            }
        },

        key_name => {
            name     => 'key_name',
            get_meth => sub { shift->get_key_name(@_) },
            get_args => [],
            set_meth => sub { shift->set_key_name(@_) },
            set_args => [],
            disp     => 'Key Name',
            search   => 1,
            len      => 64,
            req      => 1,
            type     => 'short',
            props    => {
                type      => 'text',
                length    => 32,
                maxlength => 64
            }
        },

        description => {
            get_meth => sub { shift->get_description(@_) },
            get_args => [],
            set_meth => sub { shift->set_description(@_) },
            set_args => [],
            name     => 'description',
            disp     => 'Description',
            len      => 256,
            req      => 0,
            type     => 'short',
            props    => {
                type => 'textarea',
                cols => 40,
                rows => 4
            }
        },

        top_level => {
            name     => 'top_level',
            get_meth => sub {shift->is_top_level(@_)},
            get_args => [],
            set_meth => sub {shift->set_top_level(@_)},
            set_args => [],
            disp     => 'Type',
            len      => 1,
            req      => 0,
            type     => 'short',
            props    => {
                type => 'radio',
                vals => [ [0, 'Element'], [1, 'Asset']]
            }
        },

        paginated => {
            name     => 'paginated',
            get_meth => sub {shift->is_paginated(@_)},
            get_args => [],
            set_meth => sub {shift->set_paginated(@_)},
            set_args => [],
            disp     => 'Page',
            len      => 1,
            req      => 0,
            type     => 'short',
            props    => { type => 'checkbox'}
        },

        fixed_uri    => {
            name     => 'fixed_uri',
            get_meth => sub {shift->is_fixed_uri(@_)},
            get_args => [],
            set_meth => sub {shift->set_fixed_uri(@_)},
            set_args => [],
            disp     => 'Fixed',
            len      => 1,
            req      => 0,
            type     => 'short',
            props    => { type => 'checkbox'}
        },

        related_story => {
            name     => 'related_story',
            get_meth => sub {shift->is_related_story(@_)},
            get_args => [],
            set_meth => sub {shift->set_related_story(@_)},
            set_args => [],
            disp     => 'Related Story',
            len      => 1,
            req      => 0,
            type     => 'short',
            props    => { type => 'checkbox'}
        },

        related_media => {
            name     => 'related_media',
            get_meth => sub {shift->is_related_media(@_)},
            get_args => [],
            set_meth => sub {shift->set_related_media(@_)},
            set_args => [],
            disp     => 'Related Media',
            len      => 1,
            req      => 0,
            type     => 'short',
            props    => { type => 'checkbox'}
        },

        media => {
            name     => 'media',
            get_meth => sub {shift->get_media(@_)},
            get_args => [],
            set_meth => sub {shift->set_media(@_)},
            set_args => [],
            disp     => 'Content',
            len      => 1,
            req      => 0,
            type     => 'short',
            props    => {
                type => 'radio',
                vals => [ [ 0, 'Story'], [ 1, 'Media'] ]
            }

        },

        displayed    => {
            name     => 'displayed',
            get_meth => sub {shift->is_displayed(@_)},
            get_args => [],
            set_meth => sub {shift->set_displayed(@_)},
            set_args => [],
            disp     => 'Displayed',
            len      => 1,
            req      => 0,
            type     => 'short',
            props    => { type => 'checkbox'}
        },

        biz_class_id => {
            name     => 'biz_class_id',
            get_meth => sub {shift->get_biz_class_id(@_)},
            get_args => [],
            set_meth => sub {shift->set_biz_class_id(@_)},
            set_args => [],
            disp     => 'Content Type',
            len      => 3,
            req      => 0,
            type     => 'short',
            props    => {
                type => 'select',
                vals => $sel
            }
        },

        active => {
            name     => 'active',
            get_meth => sub { shift->is_active(@_) ? 1 : 0 },
            get_args => [],
            set_meth => sub {
                $_[1] ? shift->activate(@_)
                      : shift->deactivate(@_)
            },
            set_args => [],
            disp     => 'Active',
            len      => 1,
            req      => 1,
            type     => 'short',
            props    => { type => 'checkbox' }
        },
    };

    if ($ord) {
        return wantarray ? @{$METHS}{&ORD} : [@{$METHS}{&ORD}];
    } elsif ($ident) {
        return wantarray ? $METHS->{key_name} : [$METHS->{key_name}];
    } else {
        return $METHS;
    }
}

##############################################################################

=back

=head2 Accessors

=head3 id

  my $id = $element_type->get_id;

Returns the element type object's unique database ID.

=head3 name

  my $name = $element_type->get_name;
  $element_type = $element_type->set_name($name);

Get and set the element type object's unique name.

=head3 description

  my $description = $element_type->get_description;
  $element_type = $element_type->set_description($description);

Get and set the element type object's description. The setter converts
non-Unix line endings.

=cut

sub set_description {
    my ($self, $val) = @_;
    $val =~ s/\r\n?/\n/g if defined $val;
    $self->_set( [ 'description' ] => [ $val ]);
}

=head3 key_name

  my $key_name = $element_type->get_key_name;
  $element_type = $element_type->set_key_name($key_name);

Get and set the element type object's unique key name.

=head3 top_level

  my $is_top_level = $element_type->is_top_level;
  $element_type = $element_type->set_top_level($is_top_level);

The C<top_level> attribute is a boolean that indicates whether the element
type is a story type or a media type, and therefore a top-level element. In
other words, elements based on it cannot be subelements of any other elements.

=head3 biz_type_id

  my $biz_type_id = $element_type->get_biz_type_id;
  $element_type = $element_type->set_biz_type_id($biz_type_id);

The C<biz_type_id> attribute is contains the ID for a
C<Bric::Util::Class|Bric::Util::Class> indicating the class of object with
whic the elements based on the type can be associated. The values allowed are
only those for
L<Bric::Biz::Asset::Business::Story|Bric::Biz::Asset::Business::Story>,
L<Bric::Biz::Asset::Business::Media|Bric::Biz::Asset::Business::Media>, and
the latter's subclasses.

=head3 paginated

  my $is_paginated = $element_type->is_paginated;
  $element_type = $element_type->set_paginated($is_paginated);

The C<paginated> attribute is a boolean that indicates whether the elements
based on the element type represent pages. Paginated elements generally
trigger the output of multiple files, one for each paginated element in a
document, by the burner. This attribute is ignored for top level elements.

=head3 fixed_uri

  my $is_fixed_uri = $element_type->is_fixed_uri;
  $element_type = $element_type->set_fixed_uri($is_fixed_uri);

The C<fixed_uri> attribute is a boolean that indicates whether documents based
on the element type will use the "URI Format" or "Fixed URI Format" of an
output channel through which the document is published. This attribute is
ignored for non-top level elements.

=head3 related_story

  my $is_related_story = $element_type->is_related_story;
  $element_type = $element_type->set_related_story($is_related_story);

The C<related_story> attribute is a boolean that indicates whether elements
based on the element type can have another story related to them.

=head3 related_media

  my $is_related_media = $element_type->is_related_media;
  $element_type = $element_type->set_related_media($is_related_media);

The C<related_media> attribute is a boolean that indicates whether elements
based on the element type can have another media related to them.

=head3 media

  my $is_media = $element_type->is_media;
  $element_type = $element_type->set_media($is_media);

The C<media> attribute is a boolean that indicates whether elements based on
the element type are media documents. This attribute is a redundant
combination fo the C<biz_type_id> and C<top_level> attributes.

=head3 displayed

  my $is_displayed = $element_type->is_displayed;
  $element_type = $element_type->set_displayed($is_displayed);

The C<displayed> attribute is a boolean that indicates whether elements based
on the element type are displayed in the document profile when they are first
created. Note that it's ignored for top-level elements.

=cut

# Reference is just for backwards compatibility.
for my $attr (qw(
    top_level
    paginated
    fixed_uri
    related_story
    related_media
    media
    displayed
)) {
    no strict 'refs';
    my $iser = sub { $_[0]->_get($attr) ? shift : undef };
    *{"is_$attr"}  = $iser;
    *{"get_$attr"} = $iser;
    *{"set_$attr"} = sub { shift->_set([$attr] => [shift() ? 1 : 0]) };
}

##############################################################################

=head3 biz_class_id

  my $biz_class_id   = $element_type->get_biz_class_id;
  my $biz_class_name = $element_type->get_biz_class;
  $element_type->set_biz_class_id($biz_class_id);

Get and set the ID of the Bric::Util::Class object that represents the class
for which elements of this type can be created. Must be the ID for either
L<Bric::Biz::Asset::Business::Story|Bric::Biz::Asset::Business::Story>,
L<Bric::Biz::Asset::Business::Media|Bric::Biz::Asset::Business::Media>, or one
of its subclasses. C<get_biz_class()> actually returns the package name of the
business class represented by the C<biz_class_id> attribute.

=cut

sub get_biz_class {
    my $self = shift;
    my $class = Bric::Util::Class->lookup({'id' => $self->get_biz_class_id})
        or return;
    return $class->get_pkg_name;
}

##############################################################################

=head3 primary_oc_id

  my $primary_oc_id = $element_type->get_primary_oc_id($site_id);
     $primary_oc_id = $element_type->get_primary_oc_id($site);

  $element_type->set_primary_oc_id($primary_oc_id, $site_id);
  $element_type->set_primary_oc_id($primary_oc_id, $site);

Gets and sets the primary output channel within the given site for the element
type. Either a site object or ID can be used. Only top-level element types
have site and output channel associations.

B<Throws:>

=over 4

=item *

No site parameter passed to Bric::Biz::ElementType-E<gt>set_primary_oc_id

=item *

No output channels associated with non top-level element types.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_primary_oc_id {
    my ( $self, $id, $site) = @_;

    throw_dp "No site parameter passed to " . __PACKAGE__ .
      "->set_primary_oc_id" unless $site;

    throw_dp "No output channels associated with non top-level element types"
      unless $self->get_top_level;

    $site = $site->get_id if ref $site;

    my $oc_site = $self->_get('_site_primary_oc_id');

    # If it is set and it is the same then don't bother
    return $self if ref $oc_site && defined $id && exists $oc_site->{$site}
      && $oc_site->{$site} == $id;

    $oc_site = {} unless ref $oc_site;
    $oc_site->{$site} = $id;
    $self->_set(['_site_primary_oc_id'], [$oc_site]);
    $self->_set__dirty(1);
    return $self;
}

##############################################################################

sub get_primary_oc_id {
    my ($self, $site) = @_;

    throw_dp "No site parameter passed to " . __PACKAGE__ .
      "->get_primary_oc_id" unless $site;

    throw_dp "No output channels associated with non top-level element types"
      unless $self->get_top_level;

    $site = $site->get_id if ref $site;

    my $oc_site = $self->_get('_site_primary_oc_id');
    return $oc_site->{$site} if ref $oc_site && exists $oc_site->{$site};

    $oc_site = {} unless ref $oc_site;

    my $sel = prepare_c(qq{
        SELECT primary_oc__id
        FROM   element_type__site
        WHERE  element_type__id = ? AND
               site__id    = ?
    }, undef, DEBUG);

    execute($sel, $self->get_id, $site);

    my $ret = fetch($sel);
    finish($sel);
    return unless $ret;

    my $dirty = $self->_get__dirty();
    $oc_site->{$site} = $ret->[0];
    $self->_set(['_site_primary_oc_id'],[$oc_site]);
    $self->_set__dirty($dirty);
    return $ret->[0];
}

##############################################################################

=head3 active

  my $is_active = $element_type->is_active;
  $element_type->activate;
  $element_type->deactivate;

This boolean attribute indicates whether the element type is active.

=cut

sub is_active  { $_[0]->_get('_active') ? shift : undef }
sub activate   { shift->_set(['_active'] => [1]) }
sub deactivate { shift->_set(['_active'] => [0]) }

##############################################################################
# Compatibility methods.

sub get_type_name {
    my $self = shift;
    my $att_obj = $self->_get_at_type_obj or return;
    return $att_obj->get_name;
}

sub get_type_description {
    my $self = shift;
    my $att_obj = $self->_get_at_type_obj or return;
    return $att_obj->get_description;
}

sub clear_media { shift->_set(['media'] => [0] ) }

sub get_type__id   { shift->get_type_id       }
sub set_type__id   { shift->set_type_id(@_)   }
sub get_at_grp__id { shift->get_et_grp_id     } ## Deprecated ##
sub set_at_grp__id { shift->set_et_grp_id(@_) } ## Deprecated ##
sub get_at_type    { shift->_get_at_type_obj  }
sub get_fixed_url  { shift->is_fixed_uri      }
sub get_et_grp_id {
    require Carp && Carp::carp(
    __PACKAGE__ . '->get_[e/a]t_grp_id has been deprecated and will ' .
          'be removed in a future version of Bricolage');
    return 0;
}
sub set_et_grp_id {
    require Carp && Carp::carp(
    __PACKAGE__ . '->set_[e/a]t_grp_id has been deprecated and will ' .
          'be removed in a future version of Bricolage');
    shift;
}

##############################################################################

=head2 Instance Methods

=head3 Output Channels

=over

=item get_output_channels

  my @ocs = $element_type->get_output_channels;
     @ocs = $element_type->get_output_channels(@oc_ids);
  my $ocs_aref = $element_type->get_output_channels;
     $ocs_aref = $element_type->get_output_channels(@oc_ids);

Returns a list or array reference of output channels that have been associated
with this element type. If C<@oc_ids> is passed, then only the output channels
with those IDs are returned, if they're associated with this element type.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> The objects returned will be Bric::Biz::OutputChannel::Element
objects, and these objects contain extra information relevant to the
assocation between each output channel and this element object.

=cut

sub get_output_channels { $get_oc_coll->(shift)->get_objs(@_) }


##############################################################################

=item add_output_channel

  $element_type->add_output_channel($oc);
  $element_type->add_output_channel($oc_id);

Adds an output channel to this element object and returns the resulting
Bric::Biz::OutputChannel::Element object. Can pass in either an output channel
object or an output channel ID.

B<Throws:> NONE.

B<Side Effects:> If a Bric::Biz::OutputChannel object is passed in as the
first argument, it will be converted into a Bric::Biz::OutputChannel::Element
object.

B<Notes:> NONE.

=cut

sub add_output_channel {
    my ($self, $oc) = @_;
    my $oc_coll = $get_oc_coll->($self);
    $oc_coll->new_obj({ (ref $oc ? 'oc' : 'oc_id') => $oc,
                        element_type_id => $self->_get('id') });
}

##############################################################################

=item add_output_channels

  $element_type->add_output_channels(@ocs);
  $element_type->add_output_channels(\@ocs);
  $element_type->add_output_channels(@oc_ids);
  $element_type->add_output_channels(\@oc_ids);

This accepts a list or array reference of output channel objects or IDs to be
associated with this element type.

B<Throws:> NONE.

B<Side Effects:> Any Bric::Biz::OutputChannel objects passed in will be
converted into Bric::Biz::OutputChannel::Element objects.

B<Notes:> NONE.

=cut

sub add_output_channels {
    my $self = shift;
    my $ocs = ref $_[0] eq 'ARRAY' ? shift : \@_;
    $self->add_output_channel($_) for @$ocs;
    return $self;
}

##############################################################################

=item delete_output_channels

  $element_type->delete_output_channels(@output_channels);
  $element_type->delete_output_channels(\@output_channels);

This accepts a list or array reference of output channels and removes their
association from the object.

B<Throws:>

=over 4

=item *

Cannot delete a primary output channel.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub delete_output_channels {
    my $self = shift;
    my $ocs = ref $_[0] eq 'ARRAY' ? shift : \@_;
    my $oc_coll = $get_oc_coll->($self);
    no warnings 'uninitialized';
    foreach my $oc (@$ocs) {
        $oc = Bric::Biz::OutputChannel::Element->lookup({ id => $oc })
          unless ref $oc;
        throw_dp "Cannot delete a primary output channel"
          if $self->get_primary_oc_id($oc->get_site_id) == $oc->get_id;
    }

    $oc_coll->del_objs(@$ocs);
    return $self;
}

##############################################################################

=back

=head3 Sites

=over

=item get_sites

  my @sites = $element_type->get_sites;
     @sites = $element_type->get_sites(@site_ids);
  my $sites_aref = $element_type->get_sites;
     $sites_aref = $element_type->get_sites(@site_ids);

Returns a list or array reference of sites that have been asssociated with
this element type. If C<@site_ids> is passed, then only the sites with those
IDs are returned, if they're associated with this element type.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> The objects returned will be Bric::Biz::Site objects, and these
objects contain extra information relevant to the assocation between each
output channel and this element object.

=cut

sub get_sites { $get_site_coll->(shift)->get_objs(@_) }

##############################################################################

=item add_site

  $element_type->add_site($site);
  $element_type->add_site($site_id);

Adds a site to this element object and returns the resulting Bric::Biz::Site
object. Can pass in either an site object or a site ID.

B<Throws:>

=over 4

=item *

You can only add sites to top level objects

=item *

Cannot add sites to non top-level element types.

=item *

No such site.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub add_site {
    my ($self, $site) = @_;

    throw_dp "Cannot add sites to non top-level element types"
      unless $self->get_top_level;

    my $site_coll = $get_site_coll->($self);
    $site = Bric::Biz::Site->lookup({ id =>  $site}) unless ref $site;

    throw_dp "No such site" unless ref $site;

    $site_coll->add_new_objs( $site );
    return $site;
}

##############################################################################

=item add_sites

  $element_type->add_sites(@sites);
  $element_type->add_sites(\@sites);
  $element_type->add_sites(@site_ids);
  $element_type->add_sites(\@site_ids);

This accepts a list or array reference of site objects or IDs to be associated
with this element type.

B<Throws:>

=over 4

=item *

You can only add sites to top level objects

=item *

Couldn't find site

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub add_sites {
    my $self = shift;
    my $sites = ref $_[0] eq 'ARRAY' ? shift : \@_;
    $self->add_site($_) for @$sites;
}

##############################################################################

=item remove_sites

  $element_type->remove_sites(@sites);
  $element_type->remove_sites(\@sites);

Removes a list or array reference of sites from association with the element
type.

B<Throws:>

=over 4

=item *

Cannot remove last site from an element type.

=back

B<Side Effects:> Also disassociates any output channels for the site that are
associated with this element.

B<Notes:> NONE.

=cut

sub remove_sites {
    my ($self, $sites) = @_;
    my $site_coll = $get_site_coll->($self);
    throw_dp "Cannot remove last site from an element type"
      if @{$site_coll->get_objs} < 2;

    #here we need to remove all corresponding output channels
    #for this site

    my $oces = $self->get_output_channels();
    my @delete_oc;
    for my $site (@$sites) {
        my $site_id = (ref($site) ? $site->get_id : $site);
        foreach my $oce (@$oces) {
            if ($site_id == $oce->get_site_id) {
                push @delete_oc, $oce;
                $self->set_primary_oc_id(undef, $oce->get_site_id)
                  if ($self->get_primary_oc_id($site_id) == $oce->get_id);

            }
        }
    }
    $self->delete_output_channels(\@delete_oc);
    $site_coll->del_objs(@$sites);

    return $self;
}

##############################################################################

=back

=head3 Field Types

=over

=item get_field_types

=item get_data

  my @field_types = $element_type->get_field_types;
  my $field_type  = $element_type->get_field_types($key_name);
     @field_types = $element_type->get_data;
     $field_type  = $element_type->get_data($key_name);

Returns a list or array reference of the field types that the element type
contains. Pass in a key name to get back a single field type.

B<Note:> C<get_data()> is the deprecated form of this method.

=cut

sub get_field_types {
    my ($self, $key_name) = @_;
    my $parts     = $self->_get_parts();
    my $new_parts = $self->_get('_new_parts');
    my @all = values %$parts;

    # Include the yet to be added parts.
    while (my ($id, $obj) = each %$new_parts) {
        push @all, $id == -1 ? @$obj : $obj;
    }

    return first { $_->get_key_name eq $key_name } @all
        if $key_name;

    @all = map  {         $_->[1]         }
           sort {   $a->[0] <=> $b->[0]   }
           map  { [ $_->get_place => $_ ] }
           @all;
    return wantarray ? @all : \@all;
}

sub get_data { shift->get_field_types(@_) }

##############################################################################

=item add_field_types

=item add_data

  $element_type->add_field_types(@field_types);
  $element_type->add_field_types(\@field_types);
  $element_type->add_data(@field_types);
  $element_type->add_data(\@field_types);

This takes a list of field typess and associates them with the element type
object.

B<Note:> C<add_data()> is the deprecated form of this method.

=cut

sub add_field_types {
    my $self = shift;
    my $field_types = ref $_[0] eq 'ARRAY' ? shift : \@_;
    my $parts = $self->_get_parts;
    my ($new_parts, $del_parts) = $self->_get(qw(_new_parts _del_parts));

    foreach my $p (@$field_types) {
        throw_gen 'Must pass field type object to add_field_types()'
          unless ref $p;

        # Get the ID if we were passed an object.
        my $p_id = $p->get_id;

        # Skip adding this part if it already exists.
        next if exists $parts->{$p_id};

        # Add this to the parts list.
        $new_parts->{$p_id} = $p;

        # Remove this value from the deletion list if its there.
        delete $del_parts->{$p_id};
    }

    # Update $self's new and deleted parts lists.
    $self->_set(['_del_parts'] => [$del_parts]);

    # Set the dirty bit since something has changed.
    $self->_set__dirty(1);

    return $self;
}

sub add_data { shift->add_field_types(@_) }

##############################################################################

=item new_field_type

=item new_data

  my $field_type = $element_type->new_field_type(\%params);
     $field_type = $element_type->new_data(\%params);

Adds a new field type to the element type, creating a new
Bric::Biz::ElementType::Parts::FieldType object. See
L<Bric::Biz::ElementType::Parts::FieldType|Bric::Biz::ElementType::Parts::FieldType>
for a list of the parameters to its C<new()> method for the parameters that
can be specified in the parameters hash reference passsed to
C<new_field_type()>.

B<Note:> C<new_data()> is the deprecated form of this method.

=cut

sub new_field_type {
    my ($self, $param) = @_;
    my ($new_parts) = $self->_get('_new_parts');

    # Create the new field type.
    my $part = Bric::Biz::ElementType::Parts::FieldType->new($param);

    # Add all new values to a special array of new parts until they can be
    # saved and given an ID.
    push @{$new_parts->{-1}}, $part;

    # Update $self's new parts lists.
    $self->_set(['_new_parts'] => [$new_parts]);

    # Set the dirty bit since something has changed.
    $self->_set__dirty(1);

    return $part;
}

sub new_data { shift->new_field_type(@_) }

##############################################################################

=item copy_field_type

=item copy_data

  my $field_type = $element_type->copy_field_type(\%params);
     $field_type = $element_type->copy_data(\%params);

Copies the definition for a field type from another eelement type. The
parameters expected in the hash reference argument are:

=over 4

=item field_type

=item field_obj

The field type object to copy into this element type. Required unless
C<element_type> and C<field_key_name> have been specified.

=item element_type

=item at

An existing element type object from which to extract a field to copy.
Required unless C<field_type> has been specified.

=item field_key_name

=item field_name

The key name of a field associated with the element type passed via the
C<element_type> parameter. Required unless C<field_type> has been specified.

=back

B<Note:> C<copy_data()> is the deprecated form of this method.

=cut

sub copy_field_type {
    my ($self, $param)   = @_;
    my $new_parts        = $self->_get('_new_parts');
    my $field_type       = $param->{field_type} || $param->{field_obj};

    unless ($field_type) {
        my $element_type = $param->{element_type} || $param->{at};
        throw_gen 'No field_type or element_type parameter'
            unless $element_type;
        my $key_name = $param->{field_key_name} || $param->{field_name};
        throw_gen 'No field_key_name parameter' unless defined $key_name;
        $field_type = $element_type->get_field_types($key_name);
    }

    return $self->add_field_types($field_type->copy($self->get_id));
}

sub copy_data { shift->copy_field_type(@_) }

##############################################################################

=item del_field_types

=item del_data

  $element_type->del_field_types(@field_types);
  $element_type->del_field_types(\@field_types);
  $element_type->del_data(@field_types);
  $element_type->del_data(\@field_types);

Removes the specified field types from the element type.

B<Note:> C<del_data()> is the deprecated form of this method.

=cut

sub del_field_types {
    my $self        = shift;
    my $field_types = ref $_[0] eq 'ARRAY' ? shift : \@_;
    my $parts       = $self->_get_parts;

    my ($new_parts, $del_parts) = $self->_get(qw(_new_parts _del_parts));

    for my $p (@$field_types) {
        throw_gen 'Must pass field type objects to del_field_types()'
            unless ref $p;

        # Get the ID if we were passed an object.
        my $p_id = $p->get_id;

        # Delete this part from the list and put it on the deletion list.
        if (delete $parts->{$p_id}) {
            # Add the object as a value.
            $del_parts->{$p_id} = $p;
        }

        # Remove this value from the addition list if it's there.
        delete $new_parts->{$p_id};
    }

    # Update $self's new and deleted parts lists.
    $self->_set(
        [qw(_parts _new_parts _del_parts)]
        => [$parts, $new_parts, $del_parts]
    );

    # Set the dirty bit since something has changed.
    return $self->_set__dirty(1);
}

sub del_data { shift->del_field_types(@_) }

##############################################################################

=back

=head3 Containers

=over

=item add_containers

  $element_type->add_containers(@element_types);
  $element_type->add_containers(\@element_types);
  $element_type->add_containers(@element_type_ids);
  $element_type->add_containers(\@element_type_ids);

Add element types to the element type as subelement types. This function
accepts a list or array reference of ElementTypes, or ElementType ids.

B<Throws:> NONE.

B<Side Effects:> Any Bric::Biz::ElementType objects passed in will be
converted into Bric::Biz::ElementType::Subelement objects.

B<Notes:> NONE.

=cut

sub add_containers {
    my $self = shift;
    my $subs = ref $_[0] eq 'ARRAY' ? shift : \@_;
    $self->add_container($_) for @$subs;
    return $self;
}


##############################################################################

=item add_container

  $element_type->add_container($et);
  $element_type->add_container($et_id);

Adds a subelement to this element type object and returns the resulting
Bric::Biz::ElementType::Subelement object. Can pass in either an ElementType
object or an ElementType ID.

B<Throws:> NONE.

B<Side Effects:> If a Bric::Biz::ElementType object is passed in as the
first argument, it will be converted into a Bric::Biz::ElementType::Subelement
object.

B<Notes:> NONE.

=cut

sub add_container {
    my ($self, $et) = @_;
    my $et_coll = $get_sub_coll->($self);
    $et_coll->new_obj({
        (ref $et ? 'child' : 'child_id') => $et,
        element_type_id => $self->_get('id')
    });
}




##############################################################################

=item get_containers

  my @element_types      = $element_type->get_containers;
  my @element_types      = $element_type->get_containers(@et_ids);
  my $element_types_aref = $element_type->get_containers;
  my $element_types_aref = $element_type->get_containers(@et_ids);
  my $element_type       = $element_type->get_containers($key_name);

Returns a list or array reference of subelement element types. If C<@et_ids>
is passed, then only the subelements with those IDs are returned, if they are
indeed children of this container.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> The objects returned will be Bric::Biz::ElementType::Subelement
objects, and these objects contain extra information relevant to the
assocation between each subelement of this container, and the container itself.

=cut
sub get_containers {
    my $self = shift;
    my $coll = $get_sub_coll->($self);
    return $coll->get_objs unless @_;
    return $coll->get_objs(@_) if @_ > 1 || $_[0] =~ /^\d+$/;
    my $key_name = shift;
    return first { $_->get_key_name eq $key_name } $coll->get_objs;
}


##############################################################################

=item del_containers

  $element_type->del_containers(@element_types);
  $element_type->del_containers(\@element_types);

Remove subelement element types from the element type. The subelement element
types will not be deactivated, just disassociated with the parent element
type.

=cut

sub del_containers {
    my $self = shift;
    my $ets = ref $_[0] eq 'ARRAY' ? shift : \@_;
    my $sub_coll = $get_sub_coll->($self);

    # I don't know what this is for, and I think it's unneeded
    #no warnings 'uninitialized';

    $sub_coll->del_objs(@$ets);
    return $self;
}

##############################################################################

=back

=head3 save

  $element_type->save;

Saves changes to the element type, including its subelement element type and
field type associatesions, to the database.

=cut

sub save {
    my $self = shift;

    my ($id, $oc_coll, $site_coll, $sub_coll, $primary_oc_site)
        = $self->_get(qw(id _oc_coll _site_coll _sub_coll _site_primary_oc_id));


    if ($id) {
        # Save the parts and the output channels.
        $oc_coll->save($id) if $oc_coll;

        # Save the sites if object has an id
        $site_coll->save($id, $primary_oc_site) if $site_coll;

        # Save the subelements if object has an id
        $sub_coll->save($id) if $sub_coll;
    }

    # Don't do anything else unless the dirty bit is set.
    return $self unless $self->_get__dirty;

    unless ($self->is_active) {
        # Check to see if this AT is reference anywhere. If not, delete it.
        unless ($self->_is_referenced) {
            $self->$remove;
            return $self;
        }
    }

    # First save the main object information
    if ($id) {
        $self->_update_element_type;
    } else {
        $self->_insert_element_type;
        $id = $self->_get('id');

        # Save the sites.
        $site_coll->save($id, $primary_oc_site) if $site_coll;

        # Save the output channels.
        $oc_coll->save($id) if $oc_coll;

        # Save the subelements
        $sub_coll->save($id) if $sub_coll;
    }

    # Save the mapping of primary oc per site
    if ($primary_oc_site and %$primary_oc_site) {
        my $update = prepare_c(qq{
            UPDATE element_type__site
            SET    primary_oc__id   = ?
            WHERE  element_type__id = ? AND
                   site__id         = ?
        },undef, DEBUG);
        foreach my $site_id (keys %$primary_oc_site) {
            my $oc_id = delete $primary_oc_site->{$site_id} or next;
            execute($update, $oc_id, $id, $site_id);
        }
    }

    # Save the attribute information.
    $self->_save_attr;

    # Save the parts.
    $self->_sync_parts;


    # Call our parents save method.
    return $self->SUPER::save;
}

##############################################################################

=head3 Arbitrary Attribute Management

  $val = $element_type->set_attr($name => $value);
  $val = $element_type->get_attr($name);
  $val = $element_type->del_attr($name);

Get/Set/Delete attributes on this element type.

=cut

sub set_attr {
    my ($self, $name, $val) = @_;
    my $attr_obj = $self->_get_attr_obj;

    # If we have an attr object, then populate it
    if ($attr_obj) {
        $attr_obj->set_attr({
            name     => $name,
            sql_type => 'short',
            value    => $val
        });
    }

    # Otherwise,cache this value until save.
    else {
        my $attr     = $self->_get('_attr');
        $attr->{$name} = $val;
        $self->_set(['_attr'], [$attr]);
    }

    $self->_set__dirty(1);
    return $val;
}

sub get_attr {
    my ($self, $name) = @_;
    my $attr_obj = $self->_get_attr_obj;
    return $attr_obj->get_attr({name => $name}) if $self->get_id;
    my $attr = $self->_get('_attr');
    return $attr->{$name};
}

sub del_attr {
    my ($self, $name) = @_;
    my $attr_obj = $self->_get_attr_obj;
    return $attr_obj->delete_attr({name => $name}) if $self->get_id;
    my $attr = $self->_get('_attr');
    delete $attr->{$name} unless $self->get_id;
}

sub all_attr {
    my $self = shift;

    # If we aren't saved yet, return the cache
    return $self->_get('_attr') unless $self->get_id;

    my $attr_obj = $self->_get_attr_obj;

    # HACK: This identifies attr names begining with a '_' as private and will
    # not return them.  This is being done instead of using subsystems because
    # we are using subsystems to keep ElementTypes unique from each other.
    my $ah = $attr_obj->get_attr_hash;

    # Evil delete on a hash slice based on values returned by grep...
    delete @{$ah}{ grep { substr $_, 0, 1 eq '_' } keys %$ah };
    return $ah;
}

##############################################################################

=head3 Arbitrary Attribute Metadata Management

  $val = $element_type->set_meta($name, $field => $value);
  $val = $element_type->get_meta($name => $field);
  $val = $element_type->get_meta($name);

Get/Set attribute metadata on this element type. Calling the C<get_meta()>
method without $field returns all metadata names and values as a hash.

=cut

sub set_meta {
    my ($self, $name, $field, $val) = @_;

    if (my $attr_obj = $self->_get_attr_obj) {
        $attr_obj->add_meta({
            name  => $name,
            field => $field,
            value => $val
        });
    } else {
        my $meta = $self->_get('_meta');
        $meta->{$name}->{$field} = $val;
        $self->_set(['_meta'], [$meta]);
    }
    $self->_set__dirty(1);
    return $val;
}

##############################################################################

sub get_meta {
    my ($self, $name, $field) = @_;

    if (my $attr_obj = $self->_get_attr_obj) {
        if (defined $field) {
            return $attr_obj->get_meta({
                name  => $name,
                field => $field
            });
        } else {
            my $meta = $attr_obj->get_meta({name  => $name});
            return { map { $_ => $meta->{$_}->{value} } keys %$meta };
        }
    }

    my $meta = $self->_get('_meta');
    return defined $field ? $meta->{$name}{$field}
                          : $meta->{$name}
                          ;
}

##############################################################################

=head1 Private

=head2 Private Class Methods

=over 4

=item _do_list

called from list and list ids this will query the db and return either
ids or objects

=cut

sub _do_list {
    my ($pkg, $params, $ids) = @_;
    my $tables = $SEL_TABLES;
    #my @wheres = $WHERES; ## NEED TO SPLIT THIS ON ', ' ##
    #my $tables = "$table a, $mem_table m, $map_table c";
    my @wheres = ('a.id = etm.object_id', 'etm.member__id = m.id',
                  "m.active = '1'");
    my @params;

    # Set up the child and parent parameters
    if (exists $params->{child_id}) {
        my $val = delete $params->{child_id};
        $tables .= ", subelement_type subet";
        push @wheres, "a.id = subet.parent_id";
        push @wheres, any_where($val, "subet.child_id = ?", \@params);
    }
    if (exists $params->{parent_id}) {
        my $val = delete $params->{parent_id};
        $tables .= ", subelement_type subet";
        push @wheres, "a.id = subet.child_id";
        push @wheres, any_where($val, "subet.parent_id = ?", \@params);
    }

    # Set up the active parameter.
    if (exists $params->{active}) {
        my $val = delete $params->{active};
        # Only set the active flag if they've passed a specific value.
        if (defined $val) {
            push @wheres, "a.active = ?";
            push @params, $val ? 1 : 0;
        }
    } elsif (! exists $params->{id}) {
        push @wheres, "a.active = ?";
        push @params, 1;
    } else {
        # Do nothing -- let ID return even deactivated element types.
    }

    # Set up paramters based on an ElementType::FieldType name or a map type ID.
    if (exists $params->{field_name} || exists $params->{data_name}) {
        # Add the field_type table.
        $tables .= ', field_type d';
        my $val = exists $params->{field_name} ? delete $params->{field_name}
                                               : delete $params->{data_name}
                                               ;
        push @wheres, 'd.element_type__id = a.id', any_where(
            $val,
            'LOWER(d.key_name) LIKE LOWER(?)',
            \@params
        );
    }

    # Set up the rest of the parameters.
    while (my ($k, $v) = each %$params) {
        if ($k eq 'output_channel_id' || $k eq 'output_channel') {
            $tables .= ', element_type__output_channel ao';
            push @wheres, 'ao.element_type__id = a.id';
            push @wheres, any_where($v, 'ao.output_channel__id = ?', \@params);
        } elsif ($k eq 'type_id' || $k eq 'type__id') {
            push @wheres, any_where($v, "a.type__id = ?", \@params);
        } elsif ($k eq 'id') {
            push @wheres, any_where($v, "a.$k = ?", \@params);
        } elsif ($k eq 'biz_class_id') {
            push @wheres, any_where($v, 'a.biz_class__id = ?', \@params);
        } elsif ($k eq 'grp_id') {
            # Fancy-schmancy second join.
            $tables .= ", $mem_table m2, $map_table c2";
            push @wheres, (
                'a.id = c2.object_id',
                'c2.member__id = m2.id',
                "m2.active = '1'"
            );
            push @wheres, any_where($v, 'm2.grp__id = ?', \@params);
        } elsif ($k eq 'site_id') {
            $tables .= ", element_type__site es";
            push @wheres, 'es.element_type__id = a.id', "es.active = '1'";
            push @wheres, any_where($v, 'es.site__id = ?', \@params);
        } elsif (exists $bool_attrs{$k}) {
            push @wheres, "a.$k = ?";
            push @params, $v ? 1 : 0;
        } else {
            # The "name" and "description" properties.
            push @wheres, any_where($v, "LOWER(a.$k) LIKE LOWER(?)", \@params);
        }
    }

    # Assemble and prepare the query.
    my $where = join ' AND ', @wheres;
    my ($qry_cols, $order) = $ids ? (\'DISTINCT a.id', 'a.id') :
      (\$sel_cols, 'a.name, a.id');
    my $sel = prepare_c(qq{
        SELECT $$qry_cols
        FROM   $tables
        WHERE  $where
        ORDER BY $order
    }, undef);

    # Just return the IDs, if they're what's wanted.
    return wantarray ? @{col_aref($sel, @params)} : col_aref($sel, @params)
      if $ids;

    execute($sel, @params);
    my (@d, @elems, $grp_ids);
    bind_columns($sel, \@d[0..$#sel_props]);
    $pkg = ref $pkg || $pkg;
    my $last = -1;
    while (fetch($sel)) {
        if ($d[0] != $last) {
            $last = $d[0];
            # Create a new element type object.
            my $self = $pkg->SUPER::new;
            $grp_ids = $d[$#d] = [$d[$#d]];
            $self->_set(\@sel_props, \@d);
            $self->_set__dirty; # Disable the dirty flag.
            push @elems, $self->cache_me;
        } else {
            # Append the ID.
            push @$grp_ids, $d[$#d];
        }
    }

    # Multisite element types are all the top-level for the site,
    # plus all non top-level element types.
    if ($params->{site_id} && !$params->{top_level}) {
        delete $params->{site_id};
        $params->{top_level} = 0;
        push @elems, _do_list($pkg, $params);

    }

    return wantarray ? @elems : \@elems;
}

##############################################################################

=back

=head2 Private Instance Methods

These need documenting.

=over 4

=item _is_referenced

=cut

sub _is_referenced {
    my $self = shift;
    my $rows;

    # Make sure this isn't referenced from an element.
    my $table = $self->is_media ? 'media' : 'story';
    my $sql  = "SELECT COUNT(*) FROM $table WHERE element_type__id = ?";
    my $sth  = prepare_c($sql, undef);
    execute($sth, $self->get_id);
    bind_columns($sth, \$rows);
    fetch($sth);
    finish($sth);

    return 1 if $rows;

    # Make sure this isn't used by another element type.
    my $et_id = $self->get_id;
    return 1 if Bric::Biz::ElementType->list_ids({ child_id => "$et_id" });

    # Make sure this isn't referenced from a template.
    $sql  = "SELECT COUNT(*) FROM template WHERE element_type__id = ?";
    $sth  = prepare_c($sql, undef);
    execute($sth, $self->get_id);
    bind_columns($sth, \$rows);
    fetch($sth);
    finish($sth);

    return 1 if $rows;

    return 0;
}

##############################################################################

=item $element_type->$remove

Removes this object completely from the DB. Returns 1 if active or undef
otherwise

=cut

$remove = sub {
    my $self = shift;
    my $id = $self->get_id or return;
    my $sth = prepare_c("DELETE FROM $table WHERE id = ?",
                        undef);
    execute($sth, $id);
    return $self;
};

=item _get_attr_obj

=cut

sub _get_attr_obj {
    my $self = shift;
    my $attr_obj = $self->_get('_attr_obj');

    return $attr_obj if $attr_obj;
    my $id = $self->get_id;
    $attr_obj = Bric::Util::Attribute::ElementType->new({
        object_id => $id,
        subsys    => "id_$id"
    });
    $self->_set(['_attr_obj'], [$attr_obj]);
    return $attr_obj;
}

##############################################################################

=item _get_at_type_obj

=cut

sub _get_at_type_obj {
    my $self = shift;
    my $att_obj = $self->_get('_att_obj');

    return $att_obj if $att_obj;

    if (my $att_id = $self->get_type_id) {
        $att_obj = Bric::Biz::ATType->lookup({'id' => $att_id});
        $self->_set(['_att_obj'], [$att_obj]);
    }

    return $att_obj;
}

##############################################################################

=item _save_attr

=cut

sub _save_attr {
    my $self = shift;
    my ($attr, $meta, $a_obj) = $self->_get('_attr', '_meta', '_attr_obj');
    my $id   = $self->get_id;

    unless ($a_obj) {
        $a_obj = Bric::Util::Attribute::ElementType->new({
            object_id => $id,
            subsys    => "id_$id"
        });
        $self->_set(['_attr_obj'], [$a_obj]);

        while (my ($k,$v) = each %$attr) {
            $a_obj->set_attr({
                name     => $k,
                sql_type => 'short',
                value    => $v
            });
        }

        foreach my $k (keys %$meta) {
            while (my ($f, $v) = each %{$meta->{$k}}) {
                $a_obj->add_meta({
                    name  => $k,
                    field => $f,
                    value => $v
                });
            }
        }
    }

    $a_obj->save;
}

##############################################################################

=item _sync_parts

=cut

sub _sync_parts {
    my $self = shift;
    my $parts = $self->_get_parts();
    my ($id, $new_parts, $del_parts)
        = $self->_get(qw(id _new_parts _del_parts));

    # Pull off the newly created parts.
    my $created = delete $new_parts->{-1};

    # Now that we know we have an ID for $self, set element type ID for
    for my $p_obj (@$created) {
        $p_obj->set_element_type_id($id);

        # Save the parts object.
        $p_obj->save;

        # Add it to the current parts list.
        $parts->{$p_obj->get_id} = $p_obj;
    }

    # Add parts that already existed when they were added.
    foreach my $p_id (keys %$new_parts) {
        # Delete this from the new list and grab the object.
        my $p_obj = delete $new_parts->{$p_id};

        # Save the parts object.
        $p_obj->save;

        # Add it to the current parts list.
        $parts->{$p_id} = $p_obj;
    }

    # Deactivate removed parts.
    for my $p_id (keys %$del_parts) {
        # Delete this from the deletion list and grab the object.
        my $p_obj = delete $del_parts->{$p_id};

        # This needs to happen for deleted parts.
        $p_obj->deactivate;
        $p_obj->set_min_occurrence(0);
        $p_obj->save;
    }
    return $self;
}

##############################################################################

=item $element_type->_update_element_type()

Update values in the element_type table.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _update_element_type {
    my $self = shift;

    my $sql = "UPDATE $table".
              ' SET '.join(',', map {"$_=?"} @cols).' WHERE id=?';

    my $sth = prepare_c($sql, undef);
    execute($sth, $self->_get(@props), $self->get_id);

    return $self;
}

##############################################################################

=item $element_type->_insert_element_type()

Insert new values into the element_type table.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _insert_element_type {
    my $self = shift;
    my $nextval = next_key($table);

    # Create the insert statement.
    my $sql = "INSERT INTO $table (".join(', ', 'id', @cols).') '.
              "VALUES ($nextval,".join(',', ('?') x @cols).')';

    my $sth = prepare_c($sql, undef);
    execute($sth, $self->_get(@props));

    # Set the ID of this object.
    $self->_set(['id'],[last_key($table)]);

    # And finally, register this person in the "All Element Types" group.
    $self->register_instance(INSTANCE_GROUP_ID, GROUP_PACKAGE);

    return $self;
}

##############################################################################

=item $element_type->_get_parts()

Call the list function of Bric::Biz::ElementType::Parts::Container to return a
list of conainer parts of this ElementType object, or return the existing parts
if weve already loaded them.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _get_parts {
    my $self = shift;
    my ($id, $parts) = $self->_get(qw(id _parts));

    # Do not attempt to get the ElementType parts if we don't yet have an ID.
    return unless $id;

    unless ($parts) {
        $parts = Bric::Biz::ElementType::Parts::FieldType->href({
            element_type_id => $self->get_id,
            order_by        => 'place',
            active          => 1,
        });
        $self->_set(['_parts'], [$parts]);
    }

    return $parts;
}

##############################################################################

=back

=head2 Private Functions

=over 4

=item my $oc_coll = $get_oc_coll->($element_type)

Returns the collection of output channels for this element type. The
collection is a L<Bric::Util::Coll::OCElement|Bric::Util::Coll::OCElement>
object. See that class and its parent, L<Bric::Util::Coll|Bric::Util::Coll>,
for interface details.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to prepare SQL statement.

=item *

Unable to connect to database.

=item *

Unable to select column into arrayref.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$get_oc_coll = sub {
    my $self = shift;
    my $dirt = $self->_get__dirty;
    my ($id, $oc_coll) = $self->_get('id', '_oc_coll');
    return $oc_coll if $oc_coll;
    $oc_coll = Bric::Util::Coll::OCElement->new(
        defined $id ? {element_type_id => $id} : undef
    );
    $self->_set(['_oc_coll'] => [$oc_coll]);
    $self->_set__dirty($dirt); # Reset the dirty flag.
    return $oc_coll;
};

##############################################################################

=item my $site_coll = $get_site_coll->($element_type)

Returns the collection of sites for this element type. The collection is a
L<Bric::Util::Coll::Site|Bric::Util::Coll::Site> object. See that class and
its parent, L<Bric::Util::Coll|Bric::Util::Coll>, for interface details.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to prepare SQL statement.

=item *

Unable to connect to database.

=item *

Unable to select column into arrayref.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$get_site_coll = sub {
    my $self = shift;
    my $dirt = $self->_get__dirty;
    my ($id, $site_coll) = $self->_get('id', '_site_coll');
    return $site_coll if $site_coll;
    $site_coll = Bric::Util::Coll::Site->new(
        defined $id ? {element_type_id => $id} : undef
    );
    $self->_set(['_site_coll'] => [$site_coll]);
    $self->_set__dirty($dirt); # Reset the dirty flag.
    return $site_coll;
};

##############################################################################

=item my $sub_coll = $get_sub_coll->($element_type)

Returns the collection of subelements for this element type. The collection is a
L<Bric::Util::Coll::Subelement|Bric::Util::Coll::Subelement> object. See that class and
its parent, L<Bric::Util::Coll|Bric::Util::Coll>, for interface details.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to prepare SQL statement.

=item *

Unable to connect to database.

=item *

Unable to select column into arrayref.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$get_sub_coll = sub {
    my $self = shift;
    my $dirt = $self->_get__dirty;
    my ($id, $sub_coll) = $self->_get('id', '_sub_coll');
    return $sub_coll if $sub_coll;
    $sub_coll = Bric::Util::Coll::Subelement->new(
        defined $id ? {parent_id => $id} : undef
    );
    $self->_set(['_sub_coll'] => [$sub_coll]);
    $self->_set__dirty($dirt); # Reset the dirty flag.
    return $sub_coll;
};

##############################################################################

=item my $key_name = $make_key_name->($name)

Takes an element type name and turns it into the key name. This is the name
that will be used in templates and in the super bulk edit interface.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$make_key_name = sub {
    my $n = lc($_[0]);
    $n =~ y/a-z0-9/_/cs;
    return $n;
};

1;
__END__

=back

=head1 Notes

NONE.

=head1 Author

Michael Soderstrom <miraso@pacbell.net>

Refactored by David Wheeler <david@kineticode.com>

=head1 See Also

L<Bric::Biz::Element|Bric::Biz::Element>,
L<Bric::Util::Coll::OCElement|Bric::Util::Coll::OCElement>.

=cut
