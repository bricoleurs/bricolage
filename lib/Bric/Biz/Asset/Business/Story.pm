package Bric::Biz::Asset::Business::Story;
###############################################################################

=head1 NAME

Bric::Biz::Asset::Business::Story - The interface to the Story Object

=head1 VERSION

$Revision: 1.48 $

=cut

our $VERSION = (qw$Revision: 1.48 $ )[-1];

=head1 DATE

$Date: 2003-03-23 06:57:01 $

=head1 SYNOPSIS

 # creation of new objects
 $story = Bric::Biz::Asset::Business::Story->new( $init )
 $story = Bric::Biz::Asset::Business::Story->lookup( $param )
 ($stories || @stories) = Bric::Biz::Asset::Business::Story->list($param)

 # list of object ids
 ($ids || @ids) = Bric::Biz::Asset::Business::Story->list_ids($param)


 ## METHODS INHERITED FROM Bric::Biz::Asset ##

  # General information
 $asset       = $asset->get_id()
 $asset       = $asset->set_description($description)
 $description = $asset->get_description()

 # User information
 $usr_id      = $asset->get_user__id()
 $asset       = $asset->set_user__id($usr_id)

 # Version information
 $vers_grp_id = $asset->get_version_grp__id();
 $vers_id     = $asset->get_assset_version_id();

 # Desk stamp information
 ($desk_stamp_list || @desk_stamps) = $asset->get_desk_stamps()
 $desk_stamp                        = $asset->get_current_desk()
 $asset                             = $asset->set_current_desk($desk_stamp)

 # Workflow methods.
 $id  = $asset->get_workflow_id;
 $obj = $asset->get_workflow_object;
 $id  = $asset->set_workflow_id;

 # Access note information
 $asset                 = $asset->add_note($note)
 ($note_list || @notes) = $asset->get_notes()

 # Creation and modification information.
 ($modi_date, $modi_by)       = $asset->get_modi()
 ($create_date, $create_date) = $asset->get_create()

 # Access active status
 $asset            = $asset->deactivate()
 $asset            = $asset->activate()
 ($asset || undef) = $asset->is_active()

 # Publish info
 $needs_publish = $asset->needs_publish();

 ## METHODS INHERITED FROM Bric::Biz::Asset::Business ##

 # General info
 $name = $biz->get_name()
 $biz  = $biz->set_name($name)
 $ver  = $biz->get_version()

 # AssetType information
 $name        = $biz->get_element_name()
 $at_id       = $biz->get_element__id()
 $biz         = $biz->set_element__id($at_id)

 # Tile methods
 $container_tile  = $biz->get_tile()
 @container_tiles = $biz->get_tiles()
 $biz             = $biz->add_data($at_data_obj, $data)
 $data            = $biz->get_data($name, $obj_order)
 $parts           = $biz->get_possible_data()

 # Container methods
 $new_container = $biz->add_container($at_contaier_obj)
 $container     = $biz->get_container($name, $obj_order)
 @containes     = $biz->get_possible_containers()

 # Access Categories
 $cat             = $biz->get_primary_category;
 $biz             = $biz->set_primary_category($cat);
 ($cats || @cats) = $biz->get_secondary_categories;
 $biz             = $biz->add_categories([$category, ...])
 ($cats || @cats) = $biz->get_categories()
 $biz             = $biz->delete_categories([$category, ...]);

 # Access keywords
 $biz               = $biz->add_keywords(\@kws)
 ($kw_list || @kws) = $biz->get_keywords()
 ($self || undef)   = $biz->has_keyword($keyword)
 $biz               = $biz->delete_keywords([$kw, ...])

 # Related stories
 $biz                   = $biz->add_related([$other_biz, ...])
 (@related || $related) = $biz->get_related()
 $biz                   = $biz->delete_related([$other_ba, ...])
 $rel_grp__id           = $biz->get_related_grp__id()

 # Setting extra information
 $id   = $biz->create_attr($sql_type, $length, $at_data_id, $data_param);
 $data = $biz->get_attr()
 $id   = $biz->create_map($map_class, $map_type, $data_param);

 # Change control
 $biz            = $biz->cancel()
 $biz            = $biz->revert($version)
 (undef || $biz) = $biz->checkin()
 $biz            = $biz->checkout($param)


 ## INSTANCE METHODS FOR Bric::Biz::Asset::Business::Story

 # Manipulation of slug field
 $slug  = $story->get_slug()
 $story = $story->set_slug($slug)

 # Access the source ID
 $src_id = $story->get_source__id()

 # Change control
 ($story || undef) = $story->is_current()

 # Ad string management
 $story         = $story->delete_ad_param($key)
 $ad_param_hash = $story->get_ad_param()
 $story         = $story->set_ad_param($key ,$val);

 # Publish data
 $date  = $story->get_expire_date()
 $story = $story->set_expire_date()

 $date  = $story->get_publish_date()
 $story = $story->set_publish_date()

 # Save to the database
 $story = $story->save()

=head1 DESCRIPTION

Story contains all of the data that will result in published page(s)
It contains the metadata and associations with Formatting assets.

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
use Bric::Util::Time qw(:all);
use Bric::Util::Attribute::Story;
use Bric::Util::Grp::Parts::Member::Contrib;
use Bric::Util::Grp::Story;
use Bric::Util::Fault::Exception::GEN;
use Bric::Util::Fault::Exception::DA;
use Bric::Biz::Asset::Business;
use Bric::Biz::Keyword;
use Bric::Biz::Site;

#==============================================================================#
# Inheritance                          #
#======================================#

# The parent module should have a 'use' line if you need to import from it.
# use Bric;

use base qw( Bric::Biz::Asset::Business );

#=============================================================================#
# Function Prototypes                  #
#======================================#

# None

#==============================================================================#
# Constants                            #
#======================================#

use constant DEBUG => 0;

use constant TABLE      => 'story';

use constant VERSION_TABLE => 'story_instance';

use constant ID_COL => 's.id';

use constant COLS       => qw( priority
                               source__id
                               usr__id
                               element__id
                               publish_date
                               expire_date
                               cover_date
                               current_version
                               published_version
                               workflow__id
                               publish_status
                               primary_uri
                               active
                               desk__id
                               site__id
                               alias_id);

use constant VERSION_COLS => qw( name
                                 description
                                 story__id
                                 version
                                 usr__id
                                 primary_oc__id
                                 slug
                                 checked_out);

use constant FIELDS =>  qw( priority
                            source__id
                            user__id
                            element__id
                            publish_date
                            expire_date
                            cover_date
                            current_version
                            published_version
                            workflow_id
                            publish_status
                            primary_uri
                            _active
                            desk_id
                            site_id
                            alias_id);

use constant VERSION_FIELDS => qw( name
                                   description
                                   id
                                   version
                                   modifier
                                   primary_oc_id
                                   slug
                                   checked_out);

use constant AD_PARAM => '_AD_PARAM';
use constant GROUP_PACKAGE => 'Bric::Util::Grp::Story';
use constant INSTANCE_GROUP_ID => 31;

use constant CAN_DO_LIST_IDS => 1;
use constant CAN_DO_LIST => 1;
use constant CAN_DO_LOOKUP => 1;

# relations to loop through in the big query
use constant RELATIONS => [qw( story category desk workflow)];

use constant RELATION_TABLES =>
    {
        story      => 'story_member sm',
        category   => 'story__category sc, category_member cm',
        desk       => 'desk_member dm',
        workflow   => 'workflow_member wm',
    };

use constant RELATION_JOINS =>
    {
        story      => 'sm.object_id = s.id '
                    . 'AND m.id = sm.member__id '
                    . 'AND m.active = 1',
        category   => 'sc.story_instance__id = i.id '
                    . 'AND cm.object_id = sc.category__id '
                    . 'AND m.id = cm.member__id '
                    . 'AND m.active = 1',
        desk       => 'dm.object_id = s.desk__id '
                    . 'AND m.id = dm.member__id '
                    . 'AND m.active = 1',
        workflow   => 'wm.object_id = s.workflow__id '
                    . 'AND m.id = wm.member__id '
                    . 'AND m.active = 1',
    };

# the mapping for building up the where clause based on params
use constant WHERE => 's.id = i.story__id';

use constant COLUMNS => join(', s.', 's.id', COLS) . ', ' 
            . join(', i.', 'i.id AS version_id', VERSION_COLS) . ', m.grp__id';

use constant OBJECT_SELECT_COLUMN_NUMBER => scalar COLS + 1;

# param mappings for the big select statement
use constant FROM => VERSION_TABLE . ' i, member m';

use constant PARAM_FROM_MAP =>
    {
       keyword            =>  'story_keyword sk, keyword k',
       simple             => 'story s '
                           . 'LEFT OUTER JOIN story_keyword sk '
                           . 'LEFT OUTER JOIN keyword k '
                           . 'ON (sk.keyword_id = k.id) '
                           . 'ON (s.id = sk.story_id)',
       _not_simple        => TABLE . ' s',
       grp_id             => 'member m2, story_member sm2',
       category_id        => 'story__category sc2',
       category_uri       => 'story__category sc2, category c',
    };

use constant PARAM_WHERE_MAP =>
    {
      id                     => 's.id = ?',
      active                 => 's.active = ?',
      inactive               => 's.active = ?',
      alias_id               => 's.alias_id = ?',
      site_id                => 's.site__id = ?',
      no_site_id             => 's.site__id <> ?',
      workflow__id           => 's.workflow__id = ?',
      _null_workflow__id     => 's.workflow__id IS NULL',
      primary_uri            => 'LOWER(s.primary_uri) LIKE LOWER(?)',
      element__id            => 's.element__id = ?',
      source__id             => 's.source__id = ?',
      priority               => 's.priority = ?',
      publish_status         => 's.publish_status = ?',
      publish_date_start     => 's.publish_date >= ?',
      publish_date_end       => 's.publish_date <= ?',
      cover_date_start       => 's.cover_date >= ?',
      cover_date_end         => 's.cover_date <= ?',
      expire_date_start      => 's.expire_date >= ?',
      expire_date_end        => 's.expire_date <= ?',
      desk_id                => 's.desk_id = ?',
      name                   => 'LOWER(i.name) LIKE LOWER(?)',
      title                  => 'LOWER(i.name) LIKE LOWER(?)',
      description            => 'LOWER(i.description) LIKE LOWER(?)',
      version                => 'i.version = ?',
      slug                   => 'LOWER(i.slug) LIKE LOWER(?)',
      user__id               => 'i.usr__id = ?',
      _checked_in_or_out     => 'i.checked_out = '
                              . '( SELECT max(checked_out) '
                              . 'FROM story_instance '
                              . 'WHERE version = i.version )',
      _checked_out           => 'i.checked_out = ?',
      primary_oc_id          => 'i.primary_oc__id = ?',
      category_id            => 'i.id = sc2.story_instance__id AND '
                              . 'sc2.category__id = ?',
      category_uri           => 'i.id = sc2.story_instance__id AND '
                              . 'sc2.category__id = c.id AND '
                              . 'LOWER(c.uri) LIKE LOWER(?)',
      keyword                => 'sk.story_id = s.id AND '
                              . 'k.id = sk.keyword_id AND '
                              . 'LOWER(k.name) LIKE LOWER(?)',
      _no_return_versions    => 's.current_version = i.version',
      grp_id                 => 'm2.grp__id = ? AND '
                              . 'sm2.member__id = m2.id AND '
                              . 's.id = sm2.object_id',
      simple                 => '( LOWER(k.name) LIKE LOWER(?) OR '
                              . 'LOWER(i.name) LIKE LOWER(?) OR '
                              . 'LOWER(i.description) LIKE LOWER(?) OR '
                              . 'LOWER(s.primary_uri) LIKE LOWER(?) )',
    };

use constant PARAM_ORDER_MAP =>
    {
      active              => 'active',
      inactive            => 'active',
      alias_id            => 'alias_id',
      site_id             => 'site__id',
      workflow__id        => 'workflow__id',
      primary_uri         => 'primary_uri',
      element__id         => 'element__id',
      source__id          => 'source__id',
      priority            => 'priority',
      publish_status      => 'publish_status',
      publish_date        => 'publish_date',
      cover_date          => 'cover_date',
      expire_date         => 'expire_date',
      name                => 'name',
      title               => 'name',
      description         => 'description',
      version             => 'version',
      version_id          => 'version_id',
      slug                => 'slug',
      user__id            => 'usr__id',
      _checked_out        => 'checked_out',
      primary_oc_id       => 'primary_oc__id',
      category_id         => 'category_id',
      category_uri        => 'uri',
      keyword             => 'name',
      return_versions     => 'version',
    };

use constant DEFAULT_ORDER => 'cover_date';

#==============================================================================#
# Fields                               #
#======================================#
#--------------------------------------#
# Public Class Fields
# NONE.

#--------------------------------------#
# Private Class Fields
my ($meths, @ord);
my $gen = 'Bric::Util::Fault::Exception::GEN';
my $da = 'Bric::Util::Fault::Exception::DA';

#--------------------------------------#
# Instance Fields
# NONE.

# This method of Bricolage will call 'use fields' for you and set some permissions.
BEGIN {
    Bric::register_fields
        ({
          # Public Fields
          slug            => Bric::FIELD_RDWR
          # Private Fields
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

=item $story = Bric::Biz::Asset::Business::Story->new( $initial_state )

This will create a new story object with an optionaly defined intiial state

Supported Keys:

=over 4

=item *

active

=item *

priority

=item *

title - same as name

=item *

name - Will be over ridden by title

=item *

description

=item *

workflow_id

=item *

slug

=item *

element__id - Required unless asset type object passed

=item *

element - the object required unless id is passed

=item *

source__id - required

=item *

cover_date - will set expire date in conjunction with the source

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
    $init->{'_active'} = (exists $init->{'active'}) ? $init->{'active'} : 1;
    delete $init->{'active'};
    $init->{priority} ||= 3;
    $init->{name} = delete $init->{title} if exists $init->{title};
    $self->SUPER::new($init);
}

################################################################################


=item $story = Bric::Biz::Asset::Business::Story->lookup( { id => $id })

This will return a story asset that matches the id provided

B<Throws:>

"Missing required parameter 'id'"

B<Side Effects:>

NONE

B<Notes:>

Inherited from Asset

=cut


################################################################################

=item (@stories||$stories) = Bric::Biz::Asset::Business::Story->list($params)

Returns a list or anonymous array of Bric::Biz::Asset::Business::Story objects
based on the search parameters passed via an anonymous hash. The supported
lookup keys are:

=over 4

=item *

name - the same as the title field

=item *

title

=item *

description

=item *

id - the story id

=item *

version

=item *

slug

=item *

user__id - returns the versions that are checked out by the user, otherwise
returns the most recent version

=item *

return_versions - returns past version objects as well

=item *

active - Will default to 1

=item *

inactive - Returns only inactive objects

=item *

category_id

=item *

keyword - a string (not an object)

=item *

workflow__id - workflow containing the story.  Set to undef to return
stories with no workflow.

=item *

primary_uri

=item *

category_uri

=item *

element__id

=item *

source__id

=item *

primary_oc_id

=item *

priority

=item *

publish_status - set to 1 to only return stories that have been published

=item *

publish_date_start - if end is left blank will return everything after the arg

=item *

publish_date_end - if start is left blank will return everything before the arg

=item *

cover_date_start - if end is left blank will return everything after the arg

=item *

cover_date_end - if start is left blank will return everything before the arg

=item *

expire_date_start - if end is left blank will return everything after the arg

=item *

expire_date_end - if start is left blank will return everything before the arg

=item *

Order - A property name to orer by.

=item *

OrderDirection - The direction in which to order the records, either "ASC" for
ascending (the default) or "DESC" for descending.

=item *

Limit - A maximum number of objects to return. If not specified, all objects
that match the query will be returned.

=item *

Offset - The number of objects to skip before listing the number of objects
specified by "Limit". Not used if "Limit" is not defined, and when "Limit" is
defined and "Offset" is not, no objects will be skipped.

=item *

simple - a single OR search that hits title, description, primary_uri
and keywords.

=back

B<Throws:>

=over 4

=item *

Unable to connect to database.

=item *

Unable to prepare SQL statement.

=item *

Unable to select column into arrayref.

=item *

Unable to execute SQL statement.

=item *

Unable to bind to columns to statement handle.

=item *

Unable to fetch row from statement handle.

=back

B<Side Effects:>

NONE

B<Notes:>

Inherited from Bric::Biz::Asset;

=cut


################################################################################

=back

=head2 Destructors

=over 4

=item $self->DESTROY

This is a dummy method to save autoload the time to find it

=back

=cut

sub DESTROY {
    # This method should be here even if its empty so that we don't waste time
    # making Bricolage's autoload method try to find it.
}

################################################################################

#--------------------------------------#

=head2 Public Class Methods

=over 4

=item ($ids || @ids) = Bric::Biz::Asset::Business::Story->list_ids( $criteria )

Returns a list of Story IDs that match the given criteria.

See the C<list()> method for the list of supported Keys.


B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>

Inherited from Bric::Biz::Asset

=cut

################################################################################

=item my $key_name = Bric::Biz::Asset::Business::Story->key_name()

Returns the key name of this class.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub key_name { 'story' }

################################################################################

=item $meths = Bric::Biz::Asset::Business::Story->my_meths

=item (@meths || $meths_aref) = Bric::Biz::Asset::Business::Story->my_meths(TRUE)

Returns an anonymous hash of instrospection data for this object. If called
with a true argument, it will return an ordered list or anonymous array of
intrspection data. The format for each introspection item introspection is as
follows:

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

sub my_meths {
    my ($pkg, $ord, $ident) = @_;
    return if $ident;

    # Return 'em if we got em.
    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}]
      if $meths;

    # We don't got 'em. So get 'em!
    foreach my $meth (__PACKAGE__->SUPER::my_meths(1)) {
        $meths->{$meth->{name}} = $meth;
        push @ord, $meth->{name};
    }
    push @ord, qw(slug category category_name), pop @ord;
    $meths->{slug}    = {
                          get_meth => sub { shift->get_slug(@_) },
                          get_args => [],
                          set_meth => sub { shift->set_slug(@_) },
                          set_args => [],
                          name     => 'slug',
                          disp     => 'Slug',
                          len      => 64,
                          type     => 'short',
                          props    => {   type       => 'text',
                                          length     => 32,
                                          maxlength => 64
                                      }
                         };
    $meths->{category} = {
                          get_meth => sub { shift->get_primary_category(@_) },
                          get_args => [],
                          set_meth => sub { shift->set_primary_category(@_) },
                          set_args => [],
                          name     => 'category',
                          disp     => 'Category',
                          len      => 64,
                          req      => 1,
                          type     => 'short',
                         };

    $meths->{category_name} = {
                          get_meth => sub { shift->get_primary_category(@_)->get_name },
                          get_args => [],
                          name     => 'category_name',
                          disp     => 'Category',
                          len      => 64,
                          req      => 1,
                          type     => 'short',
                         };

    # Rename element, too.
    $meths->{element} = { %{ $meths->{element} } };
    $meths->{element}{disp} = 'Story Type';

    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}];
}

################################################################################

=back

=head2 Public Instance Methods

=over 4

=item $uri = $biz->get_uri(($cat_id||$cat_obj), ($oc_id||$oc_obj))

Returns the a URL for this business asset. The  URL is determined
by the pre- and post- directory strings of an output channel, the
URI of the business object's asset type, and the cover date if the asset type
is not a fixed URL.

B<Throws:>

=over 4

=item *

No category associated with story.

=item *

Category not associated with story.

=item *

Output channel not associated with story.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_uri {
    my $self = shift;
    my ($cat, $oc) = @_;
    my $dirty = $self->_get__dirty();

    # Get the category object.
    if ($cat) {
        $cat = Bric::Biz::Category->lookup({ id => $cat})
          unless ref $cat;
        my $cats = $self->_get_categories();
        die $da->new({ msg => "Category '" . $cat->get_uri . "' not " .
                       "associated with story '" . $self->get_name . "'" })
          unless exists $cats->{$cat->get_id};
    } else {
        $cat = $self->get_primary_category;
    }

    die $da->new({ msg => "There is no category associated with story." }) unless $cat;

    # Get the output channel object.
    if ($oc) {
        $oc = Bric::Biz::OutputChannel->lookup({ id => $oc })
          unless ref $oc;
        die $da->new({ msg => "Output channel '" . $oc->get_name . "' not " .
                       "associated with story '" . $self->get_name . "'" })
          unless $self->get_output_channels($oc->get_id);
    } else {
        $oc = $self->get_primary_oc;
    }

    my $uri = $self->_construct_uri($cat, $oc);
    # Update the 'primary_uri' field if we were called with no arguments.
    $self->_set(['primary_uri'], [$uri]) unless scalar(@_);
    $self->_set__dirty($dirty);
    return $uri;
}

################################################################################

=item $story = $story->set_slug($slug);

Sets the slug for this story

B<Throws:>

'Invalid characters found in slug'

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub set_slug {
    my ($self, $slug) = @_;
#    my $dirty = $self->_get__dirty();
    if ($slug =~ m/\W/) {
        die $gen->new({ msg => 'Slug Must conform to URL character rules' });
    } else {
        $self->_set( { slug => $slug });
    }
#    $self->_set__dirty($dirty);
    return $self;
}

################################################################################

=item $slug = $story->get_slug()

returns the slug that has been set upon this story

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $story_name = $story->check_uri;

=item $story_name = $story->check_uri($user_id);

Returns name of story that has clashing URI.

=cut

sub check_uri {
    my ($self, $uid) = @_;
    my $msg;
    my $id = $self->_get('id') || 0;

    # Get the current story's output channels.
    my @ocs = $self->get_output_channels;
    die $gen->new({ msg => 'Cannot retrieve any output channels associated ' .
                           "with this story's story type element" })
      if !$ocs[0];
    # Then loop thru each category for this story.
  OUTER: foreach my $category ($self->get_categories) {
        # get stories in the same category
        my $params = { category_id => $category->get_id,
                       active      => 1,
                       site_id     => $self->get_site_id,
                     };

        my $stories = $self->list($params);
        # HACK: Get stories for the current user, too.
        if (defined $uid) {
            $params->{user__id} = $uid;
            push @$stories, $self->list($params);
        }

        # For each story that shares this category...
        foreach my $st (@$stories) {
            # Don't want to compare current story with itself.
            next if ($st->get_id == $id);

            # For each output channel, throw an error for conflicting URI.
            foreach my $st_oc ($st->get_output_channels) {
                foreach my $oc (@ocs) {
                    if ($st->get_uri($category, $st_oc) eq
                        $self->get_uri($category, $oc)) {
                        # HACK: Must get rid of the message and throw an
                        # exception, instead.
                        $msg = $st->get_name;
                        last OUTER;
                    }
                }
            }
        }
    }
    return $msg;
}

################################################################################

=item ($categories || @categories) = $ba->get_categories()

This will return a list of categories that have been associated with
the business asset

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_categories {
    my ($self) = @_;
    my $cats = $self->_get_categories();
    my @all;
    my $reset;
    foreach my $c_id (keys %$cats) {
        next if $cats->{$c_id}->{'action'}
          && $cats->{$c_id}->{'action'} eq 'delete';
        if ($cats->{$c_id}->{'object'} ){
            push @all, $cats->{$c_id}->{'object'};
        } else {
            my $cat = Bric::Biz::Category->lookup({ id => $c_id });
            $cats->{$c_id}->{'object'} = $cat;
            $reset = 1;
            push @all, $cat;
        }
    }
    if ($reset) {
        my $dirty = $self->_get__dirty();
        $self->_set({ '_categories' => $cats });
        $self->_set__dirty($dirty);
    }
    return wantarray ? @all : \@all;
}

###############################################################################

=item $cat = $story->get_primary_category()

Returns the category object that has been defined as primary

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_primary_category {
    my ($self) = @_;
    my $cats = $self->_get_categories();

    foreach my $c_id (keys %$cats) {
        if ($cats->{$c_id}->{'primary'}) {
            if ($cats->{$c_id}->{'object'} ) {
                return $cats->{$c_id}->{'object'};
            } else {
                return Bric::Biz::Category->lookup( { id => $c_id });
            }
        }
    }
    return undef;
}

################################################################################

=item $story = $story->set_primary_category($cat_id || $cat)

Defines a category as being the the primary one for this story. If a category
is aready marked as being primary, this will disassociate it.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub set_primary_category {
    my ($self, $cat) = @_;
    my $cat_id = ref $cat ? $cat->get_id : $cat;
    my $cats = $self->_get_categories();
    foreach my $c_id (keys %$cats) {
        if ($cats->{$c_id}->{'primary'}) {
            $cats->{$c_id}->{'primary'} = 0;
            $cats->{$c_id}->{'action'} = 'update'
              unless $cats->{$c_id}->{action}
              and $cats->{$c_id}->{action} eq 'insert';
        }
        if ($cat_id == $c_id) {
            $cats->{$c_id}->{'primary'} = 1;
            $cats->{$c_id}->{'action'} = 'update'
              unless $cats->{$c_id}->{action}
              and $cats->{$c_id}->{action} eq 'insert';
        }

    }
    return $self;
}

################################################################################

=item (@cats || $cats) = $story->get_secondary_categories()

Returns the non-primary categories that are associated with this story

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_secondary_categories {
    my ($self) = @_;
    my $cats = $self->_get_categories();

    my @seconds;
    foreach my $c_id (keys %$cats) {
        next if $cats->{$c_id}->{'primary'};
        if ($cats->{$c_id}->{'object'} ) {
            push @seconds, $cats->{$c_id}->{'object'};
        } else {
            push @seconds, Bric::Biz::Category->lookup( { id => $c_id });
        }
    }
    return wantarray ? @seconds : \@seconds;
}

################################################################################

=item $ba = $ba->add_categories( [ $category] )

This will take a list ref of category objects or ids and will associate them
with the business asset

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub add_categories {
    my ($self, $categories) = @_;
    my $cats = $self->_get_categories();

    foreach my $c (@$categories) {
        # get the id
        my $cat_id = ref $c ? $c->get_id() : $c;

        # if it already is associated make sure it is not going to be deleted
        if (exists $cats->{$cat_id}) {
            $cats->{$cat_id}->{'action'} = undef;
        } else {
            $cats->{$cat_id}->{'action'} = 'insert';
                        $cats->{$cat_id}->{'object'} = ref $c ? $c : undef;
        }
    }

    # store the values
    $self->_set({   '_categories' => $cats});
    # set the dirty flag
    $self->_set__dirty(1);
    return $self;
}

################################################################################

=item $ba = $ba->delete_categories([$category]);

This will take a list of categories and remove them from the asset

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub delete_categories {
    my ($self, $categories) = @_;
    my ($cats) = $self->_get_categories();

    foreach my $c (@$categories) {
        # get the id if there was an object passed
        my $cat_id = ref $c ? $c->get_id() : $c;
        # remove it from the current list and add it to the delete list
        if (exists $cats->{$cat_id} ) {
            if ($cats->{$cat_id}->{'action'}
                && $cats->{$cat_id}->{'action'} eq 'insert') {
                delete $cats->{$cat_id};
            } else {
                $cats->{$cat_id}->{'action'} = 'delete';
            }
        }
    }

    # set the values.
    $self->_set( {  '_categories' => $cats });
    $self->_set__dirty(1);
    return $self;
}

################################################################################

=item $story = $story->checkout()

Preforms story specific checkout stuff and then calls checkout on the parent
class

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub checkout {
    my ($self ,$param) = @_;
    my $cats = $self->_get_categories();
    $self->SUPER::checkout($param);

    # clone the category associations
    foreach (keys %$cats ) {
        $cats->{$_}->{'action'} = 'insert';
    }

    $self->_set__dirty(1);
    return $self;
}

################################################################################

=item my (@gids || $gids_aref) = $story->get_grp_ids

=item my (@gids || $gids_aref) = Bric::Biz::Asset::Business::Story->get_grp_ids

Returns a list or anonymous array of Bric::Biz::Group object ids representing the
groups of which this Bric::Biz::Asset::Business::Story object is a member.

B<Throws:> See Bric::Util::Grp::list().

B<Side Effects:> NONE.

B<Notes:> This list includes the Group IDs of the Desk, Workflow, and categories
in which the story is a member. [Actually, this method is currently disabled,
since categories don't actually add assets to an underlying group. If we later
find that customers need to control access to assets based on category, we'll
figure out a way to rectify this.]

=cut

#sub get_grp_ids {
#    my $self = shift;
#    my @ids = $self->SUPER::get_grp_ids;
#    # Add the category group IDs.
#    push @ids, (map { $_->get_asset_grp_id } $self->get_categories)
#      if ref $self;
#    return wantarray ? @ids : \@ids;
#}

#############################################################################

=item $story = $story->revert();

Reverts the current version to a prior version

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub revert {
    my ($self, $version) = @_;
    die $gen->new({ msg => "May not revert a non checked out version" })
      unless $self->_get('checked_out');

    my @prior_versions = __PACKAGE__->list({ id => $self->_get_id,
                                               return_versions => 1 });

    my $revert_obj;
    foreach (@prior_versions) {
        if ($_->get_version == $version) {
            $revert_obj = $_;
        }
    }

    die $gen->new({ msg => "The requested version does not exist" })
      unless $revert_obj;

    # clone information from the tables
    $self->_set({ slug => $revert_obj->get_slug });

    # clone the tiles
    # get rid of current tiles
    my $tile = $self->get_tile;
    $tile->do_delete;
    my $new_tile = $revert_obj->get_tile;

    # Delete existing contributors.
    if (my $contrib = $self->_get_contributors) {
        $self->delete_contributors([keys %$contrib]);
    }

    # Set up contributors to revert to.
    my $contrib;
    my $revert_contrib = $revert_obj->_get_contributors;
    while (my ($cid, $c) = each %$revert_contrib) {
        $c->{action} = 'insert';
        $contrib->{$cid} = $c;
    }

    $new_tile->prepare_clone;
    $self->_set({ _delete_tile         => $tile,
                  _contributors        => $contrib,
                  _update_contributors => 1,
                  _queried_contrib     => 1,
                  _tile                => $new_tile
                });

    $self->_set__dirty(1);
    return $self;
}

################################################################################

=item $story = $story->clone()

Creates an identical copy of this asset with a different id

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub clone {
    my ($self) = @_;
    my $tile = $self->get_tile();
    $tile->prepare_clone;

    my $contribs = $self->_get_contributors;
    # clone contributors
    foreach (keys %$contribs ) {
        $contribs->{$_}->{action} = 'insert';
    }

    # Clone the category associations
    my $cats = $self->_get_categories;
    map { $cats->{$_}->{action} = 'insert' } keys %$cats;

    # Clone the output channel associations.
    my @ocs = $self->get_output_channels;
    $self->del_output_channels(@ocs);
    $self->add_output_channels(@ocs);

    # Grab the keywords.
    my $kw = $self->get_keywords;

    # Reset properties. Note that if we start to make use of the attribute
    # object other than for desks, we'll have to find a way to clone it, too.
    $self->_set([qw(version current_version version_id id publish_date
                    publish_status _update_contributors _queried_cats
                    _attribute_object)],
                [0, 0, undef, undef, undef, 0, 1, 0, undef]);

    # Prepare to be saved.
    $self->_set__dirty(1);

    # HACK: Save ourselves (required by keywords -- boo!)!
    $self->save;

    # Add the keywords back in and return
    $self->add_keywords($kw);
    return $self;
}

################################################################################

=item $story = $story->save()

Updates the story object in the database

B<Throws:>
NONE

B<Side Effects:>
NONE

B<Notes:>
NONE

=cut

sub save {
    my ($self) = @_;

    # Make sure the primary uri is up to date.
    $self->_set(['primary_uri'], [$self->get_uri])
      unless ($self->get_primary_uri eq $self->get_uri);

    if ($self->_get('id')) {
        # make any necessary updates to the Main table
        $self->_update_story();
        if ($self->_get('version_id')) {
            if ($self->_get('_cancel')) {
                $self->_delete_instance();
                if ($self->_get('version') == 0) {
                    $self->_delete_story();
                }
                $self->_set( {'_cancel' => undef });
                return $self;
            } else {
                $self->_update_instance();
            }
        } else {
            $self->_insert_instance();
        }
    } else {
        if ($self->_get('_cancel')) {
            return $self;
        } else {
            # This is Brand new insert both Tables
            $self->_insert_story();
            $self->_insert_instance();
        }
    }

    $self->_sync_categories();
    $self->SUPER::save();
    $self->_set__dirty(0);
    return $self;
}

################################################################################

=back

=head1 PRIVATE

=head2 Private Class Methods

=over 4


################################################################################

=back

=head2 Private Instance Methods

=over 4

=item $contribs = $self->_get_contributors()

Returns the contributors from a cache or looks em up

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_contributors {
    my ($self) = @_;
    my ($contrib, $queried) = $self->_get('_contributors', '_queried_contrib');
    unless ($queried) {
        my $dirty = $self->_get__dirty();
        my $sql = 'SELECT member__id, place, role FROM story__contributor ' .
          'WHERE story_instance__id=? ';

        my $sth = prepare_ca($sql, undef, DEBUG);
        execute($sth, $self->_get('version_id'));
        while (my $row = fetch($sth)) {
            $contrib->{$row->[0]}->{'role'} = $row->[2];
            $contrib->{$row->[0]}->{'place'} = $row->[1];
        }
        $self->_set( { 
                      '_queried_contrib' => 1,
                      '_contributors' => $contrib 
                     });
        $self->_set__dirty($dirty);
    }
    return $contrib;
}

################################################################################

=item $self = $self->_insert_contributor( $id, $role)

Inserts a row into the mapping table for contributors

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _insert_contributor {
    my ($self, $id, $role, $place) = @_;
    my $sql = 'INSERT INTO story__contributor ' .
      ' (id, story_instance__id, member__id, place, role) ' .
      " VALUES (${\next_key('story__contributor')},?,?,?,?) ";

    my $sth = prepare_c($sql, undef, DEBUG);
    execute($sth, $self->_get('version_id'), $id, $place, $role);
    return $self;
}

################################################################################

=item $self = $self->_update_contributor($id, $role)

Updates the contributor mapping table

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _update_contributor {
    my ($self, $id, $role, $place) = @_;
    my $sql = 'UPDATE story__contributor ' .
      ' SET role=?, place=? ' .
      ' WHERE story_instance__id=? ' .
      ' AND member__id=? ';

    my $sth = prepare_c($sql, undef, DEBUG);
    execute($sth, $role, $place, $self->_get('version_id'), $id);
    return $self;
}

################################################################################

=item $self = $self->_delete_contributor($id)

Deletes the rows from these mapping tables

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _delete_contributor {
    my ($self, $id) = @_;
    my $sql = 'DELETE FROM story__contributor ' .
      ' WHERE story_instance__id=? ' .
      ' AND member__id=? ';

    my $sth = prepare_c($sql, undef, DEBUG);
    execute($sth, $self->_get('version_id'), $id);
    return $self;
}

################################################################################

=item $category_data = $self->_get_categories()

Returns the category data structure for this story

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_categories {
    my ($self) = @_;
    my ($cats, $queried) = $self->_get('_categories', '_queried_cats');

    unless ($queried) {
        my $dirty = $self->_get__dirty();
        my $sql = 'SELECT category__id, main '.
          "FROM story__category ".
          " WHERE story_instance__id=? ";

        my $sth = prepare_ca($sql, undef, DEBUG);
        execute($sth, $self->_get('version_id'));
        while (my $row = fetch($sth)) {
            $cats->{$row->[0]}->{'primary'} = $row->[1];
        }

        # Write this back in case it has not yet been defined.
        $self->_set( { '_categories' => $cats,
                       '_queried_cats' => 1 });
        $self->_set__dirty($dirty);
    }
    return $cats;
}

################################################################################

=item $ba = $ba->_sync_categories

Called by save this will make sure that all the changes in category mappings
are reflected in the database

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _sync_categories {
    my ($self) = @_;
    my $dirty = $self->_get__dirty();
    my $cats = $self->_get_categories();
    foreach my $cat_id (keys %$cats) {
        next unless $cats->{$cat_id}->{'action'};
        if ($cats->{$cat_id}->{'action'} eq 'insert') {
            my $primary = $cats->{$cat_id}->{'primary'} ? 1 : 0;
            $self->_insert_category($cat_id, $primary);
            $cats->{$cat_id}->{'action'} = undef;
        } elsif ($cats->{$cat_id}->{'action'} eq 'update') {
            my $primary = $cats->{$cat_id}->{'primary'} ? 1 : 0;
            $self->_update_category($cat_id, $primary);
            $cats->{$cat_id}->{'action'} = undef;
        } elsif ($cats->{$cat_id}->{'action'} eq 'delete') {
            $self->_delete_category($cat_id);
            delete $cats->{$cat_id};
        }
    }

    $self->_set( { '_categories' => $cats });
    $self->_set__dirty($dirty);
    return $self;
}

################################################################################

=item $ba = $ba->_insert_category($cat_id, $primary)

Adds a record that associates this ba with the category

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _insert_category {
    my ($self, $category_id,$primary) = @_;
    my $sql = "INSERT INTO story__category ".
      "(id, story_instance__id, category__id, main) ".
      "VALUES (${\next_key('story__category')},?,?,?)";

    my $sth = prepare_c($sql, undef, DEBUG);
    execute($sth, $self->_get('version_id'), $category_id, $primary);
    return $self;
}

################################################################################

=item $ba = $ba->_delete_category( $cat_id)

Removes this record for the database

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _delete_category {
    my ($self, $category_id) = @_;
    my $sql = "DELETE FROM story__category ".
      "WHERE story_instance__id=? AND category__id=? ";

    my $sth = prepare_c($sql, undef, DEBUG);
    execute($sth, $self->_get('version_id'), $category_id);
    return $self;
}

################################################################################

=item $ba = $ba->_update_category($cat_id, $primary);

Preforms an update on the row in the data base

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _update_category {
    my ($self, $category_id,$primary) = @_;
    my $sql = "UPDATE story__category ".
      "SET main=? ".
      "WHERE story_instance__id=? AND category__id=? ";

    my $sth = prepare_c($sql, undef, DEBUG);
    execute($sth, $primary, $self->_get('version_id'), $category_id);
    return $self;
}

###############################################################################

=item $attribute_obj = $self->_get_attribute_object()

Returns the attribte object for this story

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_attribute_object {
    my ($self) = @_;
    my $dirty = $self->_get__dirty();
    my $attr_obj = $self->_get('_attribute_object');
    return $attr_obj if $attr_obj;

    # Let's Create a new one if one does not exist
    $attr_obj = Bric::Util::Attribute::Story->new({ id => $self->_get('id') });
    $self->_set( {'_attribute_object' => $attr_obj} );
    $self->_set__dirty($dirty);
    return $attr_obj;
}

################################################################################

=begin comment

Commented out this method because it shouldn't actually be used anywhere.

=item $self = $self->_do_delete()

Removes the row from the database

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

#=cut

sub _do_delete {
    my ($self) = @_;
    my $delete = prepare_c(qq{
        DELETE FROM ${ \TABLE() }
        WHERE  id=?
    }, undef, DEBUG);
    execute($delete, $self->_get('id'));
}

=end comment

=cut

################################################################################

=item $self = $self->_insert_story()

Inserts a story record into the database

B<Throws:>

NONE

B<side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _insert_story {
    my ($self) = @_;
    my $sql = 'INSERT INTO ' . TABLE . ' (id, ' . join(', ', COLS) . ') '.
      "VALUES (${\next_key(TABLE)}, ". join(', ',  ('?') x COLS) .')';

    my $sth = prepare_c($sql, undef, DEBUG);
    execute($sth, $self->_get(FIELDS));
    $self->_set({ id => last_key(TABLE) });

    # And finally, register this person in the "All Stories" group.
    $self->register_instance(INSTANCE_GROUP_ID, GROUP_PACKAGE);
    return $self;
}

################################################################################

=item $self = $self->_insert_instance()

Inserts an instance record into the database

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _insert_instance {
    my ($self) = @_;
    my $sql = 'INSERT INTO '. VERSION_TABLE .
      ' (id, '.join(', ', VERSION_COLS) . ')'.
      "VALUES (${\next_key(VERSION_TABLE)}, ".
      join(', ', ('?') x VERSION_COLS) . ')';

    my $sth = prepare_c($sql, undef, DEBUG);
    execute($sth, $self->_get(VERSION_FIELDS));
    $self->_set( { version_id => last_key(VERSION_TABLE) });
    return $self;
}

################################################################################

=item $self = $self->_update_story()

Updates the story record in the database

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _update_story {
    my ($self) = @_;
    return unless $self->_get__dirty();
    my $sql = 'UPDATE ' . TABLE . ' SET ' . join(', ', map {"$_=?" } COLS) .
      ' WHERE id=? ';

    my $sth = prepare_c($sql, undef, DEBUG);
    execute($sth, $self->_get(FIELDS), $self->_get('id'));
    return $self;
}

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

sub _update_instance {
    my ($self) = @_;
    return unless $self->_get__dirty();
    my $sql = 'UPDATE ' . VERSION_TABLE .
      ' SET ' . join(', ', map {"$_=?" } VERSION_COLS) .
      ' WHERE id=? ';

    my $sth = prepare_c($sql, undef, DEBUG);
    execute($sth, $self->_get(VERSION_FIELDS), $self->_get('version_id'));
    return $self;
}

################################################################################

=item $self = $self->_delete_instance();

Deletes the version record from a cancled checkout

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _delete_instance {
    my ($self) = @_;
    my $sql = 'DELETE FROM ' . VERSION_TABLE .
      ' WHERE id=? ';

    my $sth = prepare_c($sql, undef, DEBUG);
    execute($sth, $self->_get('version_id'));
    return $self;
}

################################################################################

=item $self = $self->_delete_story();

Deletes from the story table for a story that has never been checked in

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _delete_story {
    my ($self) = @_;
    my $sql = 'DELETE FROM ' . TABLE .
      ' WHERE id=? ';

    my $sth = prepare_c($sql, undef, DEBUG);
    execute($sth, $self->_get('id'));
    return $self;
}

################################################################################

1;
__END__

=back

=head1 NOTES

NONE

=head1 AUTHOR

Michael Soderstrom <miraso@pacbell.net>

=head1 SEE ALSO

L<perl>, L<Bric>, L<Bric::Biz::Asset>, L<Bric::Biz::Asset::Business>

=cut



