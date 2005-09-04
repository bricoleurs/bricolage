package Bric::Biz::Asset::Business::Parts::Instance::Story;
###############################################################################

=head1 NAME

Bric::Biz::Asset::Business::Parts::Instance::Story - Story Instance class

=head1 VERSION

$LastChangedRevision$

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 DATE

$LastChangedDate: 2004-09-13 20:48:55 -0400 (Mon, 13 Sep 2004) $

=head1 DESCRIPTION

This class defines the common structure of story instances.   Each version of a
story has a separate instance for each input channel associated with that story.
When a story is checked out, the instances are all cloned.

=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies
use strict;

#--------------------------------------#
# Programatic Dependencies
use Bric::Util::Fault qw(:all);
use Bric::Config qw(:uri :ui);

#==============================================================================#
# Inheritance                          #
#======================================#
use base qw(Bric::Biz::Asset::Business::Parts::Instance);

#=============================================================================#
# Function Prototypes                  #
#======================================#

# None

#==============================================================================#
# Constants                            #
#======================================#

use constant DEBUG => 0;

use constant TABLE          => 'story_instance';
use constant STORY_TABLE    => 'story';

use constant COLS       => qw( name
                               description
                               input_channel__id
                               slug );

use constant STORY_COLS => qw( element__id );

use constant FIELDS     => qw( name
                               description
                               input_channel_id
                               slug );
                               
use constant STORY_FIELDS => qw( element__id );
                               
# the mapping for building up the where clause based on params
use constant WHERE => 'i.id = sisv.story_instance__id '
                    . 'AND sisv.story_version__id = v.id '
                    . 'AND v.story__id = s.id'; 
  
use constant COLUMNS => join(', i.', 'i.id', COLS) .
                        join(', s.', '', STORY_COLS);
use constant RO_COLUMNS => '';

# param mappings for the big select statement
use constant FROM => TABLE . ' i, ' . STORY_TABLE . ' s, '
                   . 'story_instance__story_version sisv, '
                   . 'story_version v';

use constant PARAM_FROM_MAP => {
       data_text            => 'story_data_tile sd',
       subelement_key_name  => 'story_container_tile sct',
       related_story_id     => 'story_container_tile sctrs',
       related_media_id     => 'story_container_tile sctrm',
};

use constant PARAM_WHERE_MAP => {
      id                     => 'i.id = ?',
      name                   => 'LOWER(i.name) LIKE LOWER(?)',
      subelement_key_name    => 'i.id = sct.object_instance_id AND LOWER(sct.key_name) LIKE LOWER(?)',
      related_story_id       => 'i.id = sctrs.object_instance_id AND sctrs.related_instance__id = ?',
      related_media_id       => 'i.id = sctrm.object_instance_id AND sctrm.related_media__id = ?',
      data_text              => 'LOWER(sd.short_val) LIKE LOWER(?) AND sd.object_instance_id = i.id',
      title                  => 'LOWER(i.name) LIKE LOWER(?)',
      description            => 'LOWER(i.description) LIKE LOWER(?)',
      slug                   => 'LOWER(i.slug) LIKE LOWER(?)',
      input_channel_id       => 'i.input_channel__id = ?',
      primary_ic             => 'v.primary_ic__id = i.input_channel__id ',
      primary_ic_id          => 'v.primary_ic__id = ? ',
      story_version_id       => 'sisv.story_version__id = ? ',
};

use constant PARAM_ANYWHERE_MAP => {
    subelement_key_name    => [ 'i.id = sct.object_instance_id',
                                'LOWER(sct.key_name) LIKE LOWER(?)' ],
    related_story_id       => [ 'i.id = sctrs.object_instance_id',
                                'sctrs.related_instance__id = ?' ],
    related_media_id       => [ 'i.id = sctrm.object_instance_id',
                                'sctrm.related_media__id = ?' ],
    data_text              => [ 'sd.object_instance_id = i.id',
                                'LOWER(sd.short_val) LIKE LOWER(?)' ],
    input_channel_id       => [ 'i.input_channel__id = ?' ],
};

use constant PARAM_ORDER_MAP => {
    name                => 'LOWER(i.name)',
    title               => 'LOWER(i.name)',
    description         => 'LOWER(i.description)',
    id                  => 'i.id',
    input_channel_id    => 'i.input_channel__id',
    slug                => 'LOWER(i.slug)',
};

use constant DEFAULT_ORDER => 'id';

use constant ID_COL => 'i.id';

use constant OBJECT_SELECT_COLUMN_NUMBER => scalar COLS + 1;

use constant CAN_DO_LIST_IDS => 1;
use constant CAN_DO_LIST => 1;
use constant CAN_DO_LOOKUP => 1;

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
                'slug'                    => Bric::FIELD_RDWR,
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

=item $story = Bric::Biz::Asset::Business::Parts::Instance->new( $initial_state )

This will create a new story instance with an optionally defined initial state

Supported Keys:

=over 4

=item *

title - same as name

=item *

name - Will be overridden by title

=item *

description

=item *

slug

=back

################################################################################

=item $asset = Bric::Biz::Asset::Business::Story->lookup({ id => $id })

=item $asset = Bric::Biz::Asset::Business::Media->lookup({ id => $id })

=item $asset = Bric::Biz::Asset::Formatting->lookup({ id => $id })

This will return an asset that matches the ID provided.

B<Throws:>

"Missing required parameter 'id'"

=cut

################################################################################

=item (@stories || $stories) = Bric::Biz::Asset::Business::Parts::Instance::Story->list($params)

=cut

=item (@ids||$ids) = Bric::Biz::Asset::Business::Parts::Instance::Story->list_ids($params)

=cut

################################################################################

#--------------------------------------#

=back

=head2 Destructors

=over 4

=item $element->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

=cut

sub DESTROY {
    # This method should be here even if its empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

###############################################################################

=item my $key_name = Bric::Biz::Asset::Business::Parts::Instance::Story->key_name()

Returns the key name of this class.

=cut

sub key_name { 'story_instance' }

#--------------------------------------#

=back

=head2 Public Class Methods

=over 4

=item $meths = Bric::Biz::Asset::Business::Parts::Instance::Story->my_meths

=item my @meths = Bric::Biz::Asset::BusinessParts::Instance::Story->my_meths(TRUE)

=item my @meths = Bric::Biz:::Asset::BusinessParts::Instance::Story->my_meths(0, TRUE)

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
                slug        => { name     => 'slug',
                                 get_meth => sub { shift->get_slug(@_) },
                                 get_args => [],
                                 set_meth => sub { shift->set_slug(@_) },
                                 set_args => [],
                                 disp     => 'Slug',
                                 len      => 64,
                                 type     => 'short',
                                 (ALLOW_SLUGLESS_NONFIXED ? () : (req => 1)),
                                 props    => {   type       => 'text',
                                                 length     => 32,
                                                 maxlength => 64
                                             }
                              }
               };

    return !$ord ? $METHS : wantarray ? @{$METHS}{@ORD} : [@{$METHS}{@ORD}];
}

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item $id = $instance->get_id()

This returns the id that uniquely identifies this asset.

=cut

################################################################################

=item $name = $self->get_name()

Returns the name field from Assets

=cut

################################################################################

=item $self = $self->set_name()

Sets the name field for Assets

=cut

################################################################################

=item $description = $self->get_description()

This returns the description for the asset

=cut

################################################################################

=item $self = $self->set_description()

This sets the description on the asset

=cut

################################################################################

=item $story = $self->set_slug($slug);

Sets the slug for this story

B<Throws:>

Slug must conform to URL character rules.

=cut

sub set_slug {
    my ($self, $slug) = @_;
    throw_invalid
      error    => 'Slug must conform to URL character rules',
      maketext => ['Slug must conform to URL character rules']
      if defined $slug && $slug =~ m/^\w.-_/;

    my $old = $self->_get('slug');
    $self->_set([qw(slug _update_uri)] => [$slug, 1])
      if (not defined $slug && defined $old)
      || (defined $slug && not defined $old)
      || ($slug ne $old);
    # Set the primary URI.
#    $self->get_uri;
    return $self;
}

################################################################################

=item $slug = $self->get_slug()

returns the slug that has been set upon this story

=cut

################################################################################

=item $instance = $self->clone()

Creates an identical copy of this asset with a different id

=cut

################################################################################

=item $instance = $instance->save()

Updates the instance object in the database

=cut

################################################################################

=item $element = $instance->get_element

 my $element = $instance->get_element;

Returns the top level element that contains content for this document.

=cut

#==============================================================================#

=back

=head1 PRIVATE

NON

=head2 Private Class Methods

NONE

=head2 Private Instance Methods

=item $self = $self->_insert_instance()

Inserts an instance record into the database

=cut

################################################################################

=item $self = $self->_update_instance()

Updates the record for the story instance

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

1;
__END__

=head1 NOTES

NONE

=head1 AUTHOR

michael soderstrom <miraso@pacbell.net>

=head1 SEE ALSO

L<perl>, L<Bric>, L<Bric::Biz::Asset::Business::Story>,
L<Bric::Biz::Asset::Business::Media>, L<Bric::Biz::AssetType>,
L<Bric::Biz::Asset::Business::Parts::Tile::Container>,
L<Bric::Biz::Asset::Business::Parts::Tile::Tile>

=cut

