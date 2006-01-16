package Bric::Biz::Asset::Business::Story;
###############################################################################

=head1 NAME

Bric::Biz::Asset::Business::Story - The interface to the Story Object

=head1 VERSION

$LastChangedRevision$

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 DATE

$LastChangedDate$

=head1 SYNOPSIS

 # creation of new objects
 $story = Bric::Biz::Asset::Business::Story->new( $init )
 $story = Bric::Biz::Asset::Business::Story->lookup( $param )
 ($stories || @stories) = Bric::Biz::Asset::Business::Story->list($param)

 # list of object ids
 ($ids || @ids) = Bric::Biz::Asset::Business::Story->list_ids($param)

 # Type of workflow.
 my $wf_type = Bric::Biz::Asset::Business::Story->workflow_type;

  # General information
 $asset       = $asset->get_id()
 $asset       = $asset->set_description($description)
 $description = $asset->get_description()

 # User information
 $usr_id      = $asset->get_user__id()
 $asset       = $asset->set_user__id($usr_id)

 # Version information
 $vers_grp_id = $asset->get_version_grp__id();
 $vers_id     = $asset->get_asset_version_id();

 # Desk information
 $desk        = $asset->get_current_desk;
 $asset       = $asset->set_current_desk($desk);

 # Workflow methods.
 $id  = $asset->get_workflow_id;
 $obj = $asset->get_workflow_object;
 $id  = $asset->set_workflow_id;

 # Access note information
 $asset                 = $asset->add_note($note)
 ($note_list || @notes) = $asset->get_notes()

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
 $biz               = $biz->del_keywords([$kw, ...])

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

Story contains all of the data that will result in published page(s) It
contains the metadata and associations with story documents. It inherits from
L<Bric::Biz::Asset::Business|Bric::Biz::Asset::Business>

=cut


#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies
use strict;

#--------------------------------------#
# Programatic Dependencies
use Bric::Biz::Workflow qw(STORY_WORKFLOW);
use Bric::Config qw(:uri :ui);
use Bric::Util::DBI qw(:all);
use Bric::Util::Time qw(:all);
use Bric::Util::Attribute::Story;
use Bric::Util::Grp::Parts::Member::Contrib;
use Bric::Util::Grp::Story;
use Bric::Util::Fault qw(:all);
use Bric::Biz::Asset::Business;
use Bric::Biz::Keyword;
use Bric::Biz::OutputChannel qw(:case_constants);
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
                               first_publish_date
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
                            first_publish_date
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

use constant GROUP_COLS => ('id_list(DISTINCT m.grp__id) AS grp_id',
                            'id_list(DISTINCT c.asset_grp_id) AS cat_grp_id',
                            'id_list(DISTINCT w.asset_grp_id) AS wf_grp_id');

# the mapping for building up the where clause based on params
use constant WHERE => 's.id = i.story__id '
  . 'AND sm.object_id = s.id '
  . 'AND m.id = sm.member__id '
  . 'AND m.active = 1 '
  . 'AND sc.story_instance__id = i.id '
  . 'AND c.id = sc.category__id '
  . 'AND s.workflow__id = w.id';

use constant COLUMNS => join(', s.', 's.id', COLS) . ', '
            . join(', i.', 'i.id', VERSION_COLS);

use constant OBJECT_SELECT_COLUMN_NUMBER => scalar COLS + 1;

# param mappings for the big select statement
use constant FROM => VERSION_TABLE . ' i';

use constant PARAM_FROM_MAP => {
       keyword              => 'story_keyword sk, keyword k',
       output_channel_id    => 'story__output_channel soc',
       simple               => 'story_member sm, member m, story__category sc, '
                               . 'category c, workflow w, ' . TABLE . ' s ',
       grp_id               => 'member m2, story_member sm2',
       category_id          => 'story__category sc2',
       primary_category_id  => 'story__category sc2',
       category_uri         => 'story__category sc2',
       data_text            => 'story_data_tile sd',
       contrib_id           => 'story__contributor sic',
       element_key_name     => 'element e',
       'story.category'     => 'story__category sc2',
       subelement_key_name  => 'story_container_tile sct',
};

PARAM_FROM_MAP->{_not_simple} = PARAM_FROM_MAP->{simple};

use constant PARAM_WHERE_MAP => {
      id                     => 's.id = ?',
      active                 => 's.active = ?',
      inactive               => 's.active = ?',
      alias_id               => 's.alias_id = ?',
      site_id                => 's.site__id = ?',
      no_site_id             => 's.site__id <> ?',
      version_id             => 'i.id = ?',
      workflow__id           => 's.workflow__id = ?',
      workflow_id            => 's.workflow__id = ?',
      _null_workflow_id      => 's.workflow__id IS NULL',
      primary_uri            => 'LOWER(s.primary_uri) LIKE LOWER(?)',
      element_id             => 's.element__id = ?',
      element__id            => 's.element__id = ?',
      element_key_name       => 's.element__id = e.id AND LOWER(e.key_name) LIKE LOWER(?)',
      source_id              => 's.source__id = ?',
      source__id             => 's.source__id = ?',
      priority               => 's.priority = ?',
      publish_status         => 's.publish_status = ?',
      first_publish_date_start => 's.first_publish_date >= ?',
      first_publish_date_end   => 's.first_publish_date <= ?',
      publish_date_start     => 's.publish_date >= ?',
      publish_date_end       => 's.publish_date <= ?',
      cover_date_start       => 's.cover_date >= ?',
      cover_date_end         => 's.cover_date <= ?',
      expire_date_start      => 's.expire_date >= ?',
      expire_date_end        => 's.expire_date <= ?',
      unexpired              => '(s.expire_date IS NULL OR s.expire_date > CURRENT_TIMESTAMP)',
      desk_id                => 's.desk__id = ?',
      name                   => 'LOWER(i.name) LIKE LOWER(?)',
      subelement_key_name    => 'i.id = sct.object_instance_id AND LOWER(sct.key_name) LIKE LOWER(?)',
      data_text              => 'LOWER(sd.short_val) LIKE LOWER(?) AND sd.object_instance_id = i.id',
      title                  => 'LOWER(i.name) LIKE LOWER(?)',
      description            => 'LOWER(i.description) LIKE LOWER(?)',
      version                => 'i.version = ?',
      published_version      => 's.published_version = i.version AND i.checked_out = 0',
      slug                   => 'LOWER(i.slug) LIKE LOWER(?)',
      user__id               => 'i.usr__id = ?',
      user_id                => 'i.usr__id = ?',
      _checked_in_or_out     => 'i.checked_out = '
                              . '( SELECT max(checked_out) '
                              . 'FROM story_instance '
                              . 'WHERE version = i.version '
                              . 'AND story__id = i.story__id )',
      checked_in             => 'i.checked_out = '
                              . '( SELECT min(checked_out) '
                              . 'FROM story_instance '
                              . 'WHERE version = i.version '
                              . 'AND story__id = i.story__id )',
      _checked_out           => 'i.checked_out = ?',
      checked_out            => 'i.checked_out = ?',
      _not_checked_out       => 'i.checked_out = 0 AND s.id not in '
                              . '(SELECT story__id FROM story_instance '
                              . 'WHERE s.id = story_instance.story__id '
                              . 'AND story_instance.checked_out = 1)',
      primary_oc_id          => 'i.primary_oc__id = ?',
      output_channel_id      => '(i.id = soc.story_instance__id AND '
                              . '(soc.output_channel__id = ? OR '
                              . 'i.primary_oc__id = ?))',
      category_id            => 'i.id = sc2.story_instance__id AND '
                              . 'sc2.category__id = ?',
      primary_category_id    => 'i.id = sc2.story_instance__id AND '
                              . 'sc2.category__id = ? AND sc2.main = 1',
      category_uri           => 'i.id = sc2.story_instance__id AND '
                              . 'sc2.category__id = c.id AND '
                              . 'LOWER(c.uri) LIKE LOWER(?)',
      'story.category'       => 's.id <> ? '
                              . 'AND i.id = sc2.story_instance__id AND '
                              . 'sc2.category__id in ('
                              . 'SELECT sc3.category__id '
                              . 'FROM   story__category sc3, story s2, story_instance i2 '
                              . 'WHERE  i2.story__id = s2.id '
                              . 'AND i2.version = s2.current_version '
                              . 'AND i2.checked_out =('
                              . 'SELECT MAX(checked_out) '
                              . 'FROM story_instance '
                              . 'WHERE version = i2.version '
                              . 'AND story__id = s2.id ) '
                              . 'AND sc3.story_instance__id = i2.id '
                              . 'AND s2.id = ?)',
      keyword                => 'sk.story_id = s.id AND '
                              . 'k.id = sk.keyword_id AND '
                              . 'LOWER(k.name) LIKE LOWER(?)',
      _no_return_versions    => 's.current_version = i.version',
      grp_id                 => 'm2.grp__id = ? AND '
                              . 'm2.active = 1 AND '
                              . 'sm2.member__id = m2.id AND '
                              . 's.id = sm2.object_id',
      simple                 => 's.id IN ('
                              . 'SELECT ss.id FROM story ss '
                              . 'JOIN story_instance si2 ON story__id = ss.id '
                              . 'WHERE LOWER(si2.name) LIKE LOWER(?) '
                              . 'OR LOWER(si2.description) LIKE LOWER(?) '
                              . 'OR LOWER(ss.primary_uri) LIKE LOWER(?) '
                              . 'UNION SELECT story_id FROM story_keyword '
                              . 'JOIN keyword kk ON (kk.id = keyword_id) '
                              . 'WHERE LOWER(kk.name) LIKE LOWER(?))',
      contrib_id             => 'i.id = sic.story_instance__id AND sic.member__id = ?',
};

use constant PARAM_ANYWHERE_MAP => {
    element_key_name       => [ 's.element__id = e.id',
                                'LOWER(e.key_name) LIKE LOWER(?)' ],
    subelement_key_name    => [ 'i.id = sct.object_instance_id',
                                'LOWER(sct.key_name) LIKE LOWER(?)' ],
    data_text              => [ 'sd.object_instance_id = i.id',
                                'LOWER(sd.short_val) LIKE LOWER(?)' ],
    output_channel_id      => [ 'i.id = soc.story_instance__id',
                                'soc.output_channel__id = ?' ],
    category_id            => [ 'i.id = sc2.story_instance__id',
                                'sc2.category__id = ?' ],
    primary_category_id    => [ 'i.id = sc2.story_instance__id AND sc2.main = 1',
                                'sc2.category__id = ?' ],
    category_uri           => [ 'i.id = sc2.story_instance__id AND sc2.category__id = c.id',
                                'LOWER(c.uri) LIKE LOWER(?)' ],
    keyword                => [ 'sk.story_id = s.id AND k.id = sk.keyword_id',
                                'LOWER(k.name) LIKE LOWER(?)' ],
    grp_id                 => [ 'm2.active = 1 AND sm2.member__id = m2.id AND s.id = sm2.object_id',
                                'm2.grp__id = ?' ],
    contrib_id             => [ 'i.id = sic.story_instance__id',
                                'sic.member__id = ?' ],
};

use constant PARAM_ORDER_MAP => {
    active              => 's.active',
    inactive            => 's.active',
    alias_id            => 's.alias_id',
    site_id             => 's.site__id',
    workflow__id        => 's.workflow__id',
    workflow_id         => 's.workflow__id',
    primary_uri         => 'LOWER(s.primary_uri)',
    element_id          => 's.element__id',
    element__id         => 's.element__id',
    source_id           => 's.source__id',
    source__id          => 's.source__id',
    priority            => 's.priority',
    publish_status      => 's.publish_status',
    first_publish_date  => 's.first_publish_date',
    publish_date        => 's.publish_date',
    cover_date          => 's.cover_date',
    expire_date         => 's.expire_date',
    name                => 'LOWER(i.name)',
    title               => 'LOWER(i.name)',
    description         => 'LOWER(i.description)',
    version             => 'i.version',
    version_id          => 'i.id',
    slug                => 'LOWER(i.slug)',
    user_id             => 'i.usr__id',
    user__id            => 'i.usr__id',
    _checked_out        => 'i.checked_out',
    primary_oc_id       => 'i.primary_oc__id',
    category_id         => 'sc2.category_id',
    category_uri        => 'LOWER(c.uri)',
    keyword             => 'LOWER(k.name)',
    return_versions     => 'i.version',
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

This will create a new story object with an optionally defined initial state

Supported Keys:

=over 4

=item *

user__id - Required.

=item *

active

=item *

priority

=item *

title - same as name

=item *

name - Will be overridden by title

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

site_id - required

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
    $init->{_queried_cats} = 1;
    $init->{_categories} = {};
    $init->{name} = delete $init->{title} if exists $init->{title};
    push @{$init->{grp_ids}}, INSTANCE_GROUP_ID;
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

=item title

The title of the story. May use C<ANY> for a list of possible values.

=item name

Same as C<title>.

=item description

Story description. May use C<ANY> for a list of possible values.

=item id

The story ID. May use C<ANY> for a list of possible values.

=item version

The story version number. May use C<ANY> for a list of possible values.

=item version_id

The ID of a version of a story. May use C<ANY> for a list of possible values.

=item slug

The story slug. May use C<ANY> for a list of possible values.

=item user_id

Returns the versions that are checked out by the user, otherwise returns the
most recent version. May use C<ANY> for a list of possible values.

=item checked_out

Indicates whether to list stories that are checked out or not. If "0", then
only non-checked out stories will be returned. If "1", then only checked-out
stories will be returned. If "all", then the checked_out attributed will be
ignored (unless the C<user__id> parameter is passed).

=item checked_in

If passed a true value, this parameter causes the checked in version of the
most current version of the story to be returned. When a story is checked out,
there are two instances of the current version: the one checked in last, and
the one currently being edited. When the C<checked_in> parameter is a true
value, then the instance last checked in is returned, rather than the instance
currently checked out. This is useful for users who do not currently have a
story checked out and wish to see the story as of the last check in, rather
than as currently being worked on in the current checkout. If a story is not
currently checked out, this parameter has no effect.

=item published_version

Returns the versions of the stories as they were last published. The
C<checked_out> parameter will be ignored if this parameter is passed a true
value.

=item return_versions

Boolean indicating whether to return pass version objects for each story
listed.

=item active

Boolean indicating whether to return active or inactive stories.

=item inactive

Returns only inactive stories.

=item alias_id

Returns a list of stories aliased to the story ID passed as its value. May use
C<ANY> for a list of possible values.

=item category_id

Returns a list of stories in the category represented by a category ID. May
use C<ANY> for a list of possible values.

=item category_uri

Returns a list of stories with a given category URI. May use C<ANY> for a list
of possible values.

=item keyword

Returns stories associated with a given keyword string (not object). May use
C<ANY> for a list of possible values.

=item workflow_id

Return a list of stories in the workflow represented by the workflow ID. May
use C<ANY> for a list of possible values.

=item desk_id

Returns a list of stories on a desk with the given ID. May use C<ANY> for a
list of possible values.

=item primary_uri

Returns a list of stories with a given primary URI. May use C<ANY> for a list
of possible values.

=item story.category

Pass in a story ID, and a list of stories in the same categories as the story
with that ID will be returned, minus the story with that ID. This parameter
triggers a complex join, which can slow the query time significantly on
underpowered servers or systems with a large number of stories. Still, it can
be very useful in templates that want to create a list of stories in all of
the categories the current story is in. But be sure to use the <Limit>
parameter!

=item site_id

Returns a list of stories associated with a given site ID. May use C<ANY>
for a list of possible values.

=item element_id

Returns a list of stories associated with a given element ID. May use C<ANY>
for a list of possible values.

=item source_id

Returns a list of stories associated with a given source ID. May use C<ANY>
for a list of possible values.

=item output_channel_id

Returns a list of stories associated with a given output channel ID. May use
C<ANY> for a list of possible values.

=item primary_oc_id

Returns a list of stories associated with a given primary output channel
ID. May use C<ANY> for a list of possible values.

=item priority

Returns a list of stories associated with a given priority value. May use
C<ANY> for a list of possible values.

=item contrib_id

Returns a list of stories associated with a given contributor ID. May use
C<ANY> for a list of possible values.

=item grp_id

Returns a list of stories that are members of the group with the specified
group ID. May use C<ANY> for a list of possible values.

=item publish_status

Boolean value indicating whether to return published or unpublished stories.

=item first_publish_date_start

Returns a list of stories first published on or after a given date/time.

=item first_publish_date_end

Returns a list of stories first published on or before a given date/time.

=item publish_date_start

Returns a list of stories last published on or after a given date/time.

=item publish_date_end

Returns a list of stories last published on or before a given date/time.

=item cover_date_start

Returns a list of stories with a cover date on or after a given date/time.

=item cover_date_end

Returns a list of stories with a cover date on or before a given date/time.

=item expire_date_start

Returns a list of stories with a expire date on or after a given date/time.

=item expire_date_end

Returns a list of stories with a expire date on or before a given date/time.

=item unexpired

A boolean parameter. Returns a list of stories without an expire date, or with
an expire date set in the future.

=item element_key_name

The key name for the story type element. May use C<ANY> for a list of possible
values.

=item subelement_key_name

The key name for a container element that's a subelement of a story. May use
C<ANY> for a list of possible values.

=item data_text

Text stored in the fields of the story element or any of its subelements. Only
fields that use the "short" storage type will be searched. May use C<ANY> for
a list of possible values.

=item Order

A property name to order by.

=item OrderDirection

The direction in which to order the records, either "ASC" for ascending (the
default) or "DESC" for descending.

=item Limit

A maximum number of objects to return. If not specified, all objects that
match the query will be returned.

=item Offset

The number of objects to skip before listing the remaining objcts or the
number of objects specified by C<Limit>.

=item simple

Triggers a single OR search that hits title, description, primary_uri and
keywords.

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

Returns an unordered list or array reference of story object IDs that match
the criteria defined. The criteria are the same as those for the C<list()>
method except for C<Order> and C<OrderDirection>, which C<list_ids()> ignore.

See the C<list()> method for the list of supported Keys.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Inherited from Bric::Biz::Asset.

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

Returns an anonymous hash of introspection data for this object. If called
with a true argument, it will return an ordered list or anonymous array of
introspection data. The format for each introspection item introspection is as
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

An anonymous hash of key/value pairs representing the values and display names
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
    push @ord, qw(slug), pop @ord;
    $meths->{slug}    = {
                          get_meth => sub { shift->get_slug(@_) },
                          get_args => [],
                          set_meth => sub { shift->set_slug(@_) },
                          set_args => [],
                          name     => 'slug',
                          disp     => 'Slug',
                          len      => 64,
                          type     => 'short',
                          (ALLOW_SLUGLESS_NONFIXED ? () : (req => 1)),
                          props    => {   type       => 'text',
                                          length     => 32,
                                          maxlength => 64
                                      }
                         };

    # Rename element, too.
    $meths->{element} = { %{ $meths->{element} } };
    $meths->{element}{disp} = 'Story Type';

    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}];
}

################################################################################

=item my $wf_type = Bric::Biz::Asset::Business::Story->workflow_type

Returns the value of the Bric::Biz::Workflow C<STORY_WORKFLOW> constant.

=cut

sub workflow_type { STORY_WORKFLOW }

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
    my ($cat, $oc, $no_file) = @_;
    my $dirty = $self->_get__dirty();

    # Get the category object.
    if ($cat) {
        $cat = Bric::Biz::Category->lookup({ id => $cat })
          unless ref $cat;
        my $cats = $self->_get_categories();
        throw_da(error => "Category '" . $cat->get_uri . "' not " .
                 "associated with story '" . $self->get_name . "'")
          unless exists $cats->{$cat->get_id};
    } else {
        $cat = $self->get_primary_category;
    }

    throw_da "There is no category associated with story '" .
      ($self->get_name || '') . "' (#" . ($self->get_id || '') . ")."
      unless $cat;

    # Get the output channel object.
    if ($oc) {
        $oc = Bric::Biz::OutputChannel->lookup({ id => $oc })
          unless ref $oc;
        throw_da(error => "Output channel '" . $oc->get_name . "' not " .
                 "associated with story '" . $self->get_name . "'")
          unless $self->get_output_channels($oc->get_id);
    } else {
        $oc = $self->get_primary_oc;
    }

    my $uri = $self->_construct_uri($cat, $oc);

    if (STORY_URI_WITH_FILENAME and not $no_file) {
        my $fname = $oc->can_use_slug ?
          $self->_get('slug') || $oc->get_filename :
          $oc->get_filename;
        if ($fname) {
            my $ext = $oc->get_file_ext;
            $fname .= ".$ext" if $ext ne '';
            my $uri_case = $oc->get_uri_case;
            if ($uri_case != MIXEDCASE) {
                $fname = $uri_case == LOWERCASE ? lc $fname : uc $fname;
            }
            $uri = Bric::Util::Trans::FS->cat_uri($uri, $fname);
        }
    }

    # Update the 'primary_uri' field if we were called with no arguments.
    $self->_set(['primary_uri'], [$uri]) unless scalar(@_);
    $self->_set__dirty($dirty);
    return $uri;
}

################################################################################

=item $story = $story->set_slug($slug);

Sets the slug for this story

B<Throws:>

Slug Must conform to URL character rules.

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub set_slug {
    my ($self, $slug) = @_;
    throw_invalid
      error    => 'Slug Must conform to URL character rules',
      maketext => ['Slug Must conform to URL character rules']
      if defined $slug && $slug =~ m/^\w.-_/;

    my $old = $self->_get('slug');
    $self->_set([qw(slug _update_uri)] => [$slug, 1])
      if (not defined $slug && defined $old)
      || (defined $slug && not defined $old)
      || ($slug ne $old);
    # Set the primary URI.
    $self->get_uri;
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

=item ($categories || @categories) = $ba->get_categories()

This will return a list of categories that have been associated with
the business asset.

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
    foreach my $c_id (keys %$cats) {
        next if $cats->{$c_id}->{action} and
          $cats->{$c_id}->{action} eq 'delete';
        push @all, $cats->{$c_id}->{object} ||=
          Bric::Biz::Category->lookup({ id => $c_id });
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
                return Bric::Biz::Category->lookup({ id => $c_id });
            }
        }
    }
    return undef;
}

################################################################################

=item $story = $story->set_primary_category($cat_id || $cat)

Defines a category as being the the primary one for this story. If a category
is already marked as being primary, this will disassociate it.

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
              unless $cats->{$c_id}->{action};
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
    my $reset;
    foreach my $c_id (keys %$cats) {
        next if $cats->{$c_id}->{'primary'};

        next if $cats->{$c_id}->{'action'}
          && $cats->{$c_id}->{'action'} eq 'delete';
        if ($cats->{$c_id}->{'object'} ) {
            push @seconds, $cats->{$c_id}->{'object'};
        } else {
            my $cat = Bric::Biz::Category->lookup({ id => $c_id });
            $cats->{$c_id}->{'object'} = $cat;
            $reset = 1;
            push @seconds, $cat;
        }
    }
    if ($reset) {
        my $dirty = $self->_get__dirty();
        $self->_set({ '_categories' => $cats });
        $self->_set__dirty($dirty);
    }
    return wantarray ? @seconds : \@seconds;
}

################################################################################

=item $ba = $ba->add_categories( [ $category] )

This will take a list ref of category objects or ids and will associate them
with the business asset

B<Side Effects:>

Adds the asset_grp_ids of the categories to grp_ids (unless they are already there).

=cut

sub add_categories {
    my ($self, $categories) = @_;
    my $cats = $self->_get_categories();
    my @grp_ids = $self->get_grp_ids();
    my $check = 0;
    foreach my $c (@$categories) {
        # get the id
        my $cat_id = ref $c ? $c->get_id() : $c;
        my $asset_grp_id = ref $c ? $c->get_asset_grp_id()
          : Bric::Biz::Category->lookup({ id => $c })->get_asset_grp_id;
        # if it already is associated make sure it is not going to be deleted
        if (exists $cats->{$cat_id}) {
            $cats->{$cat_id}->{'action'} = undef;
        } else {
            $cats->{$cat_id}->{'action'} = 'insert';
            $cats->{$cat_id}->{'object'} = ref $c ? $c : undef;
            push @grp_ids, $asset_grp_id;
            $check = 1;
        }
    }
    # store the values
    $self->_set([qw(grp_ids _categories _update_uri)] =>
                [\@grp_ids, $cats, $check]);
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
    my @grp_ids = $self->get_grp_ids();
    my $check = $self->_get('_update_uri');
    foreach my $c (@$categories) {
        # get the id if there was an object passed
        my $cat_id = ref $c ? $c->get_id() : $c;
        # remove it from the current list and add it to the delete list
        next unless exists $cats->{$cat_id};
        if ($cats->{$cat_id}->{'action'}
            && $cats->{$cat_id}->{'action'} eq 'insert') {
            delete $cats->{$cat_id};
        } else {
            $cats->{$cat_id}->{'action'} = 'delete';
            $check ||= 1;
        }
        my $asset_grp_id = ref $c ? $c->get_asset_grp_id()
          : Bric::Biz::Category->lookup({ id => $c })->get_asset_grp_id;
        my @n_grp_ids;
        foreach (@grp_ids) {
            push @n_grp_ids, $_ unless $_ == $asset_grp_id;
        }
        @grp_ids = @n_grp_ids;
    }
    # set the values.
    $self->_set([qw(grp_ids   _categories _update_uri)] =>
                [  \@grp_ids, $cats,      $check]);
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
    throw_gen(error => "May not revert a non checked out version")
      unless $self->_get('checked_out');

    my $revert_obj = __PACKAGE__->lookup({
        id          => $self->_get_id,
        version     => $version,
    }) or throw_gen "The requested version does not exist";

    # Clone the basic properties of the story.
    my @attrs = qw(name description slug);
    $self->_set(\@attrs, [$revert_obj->_get(@attrs)]);

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

    # Make sure the current version is cached.
    return $self->cache_me;
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
    # Uncache the story, so that the clone isn't returned when looking up
    # the original ID.
    $self->uncache_me;

    # Clone the element.
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
                    _attribute_object _update_uri first_publish_date
                    published_version)],
                [0, 0, undef, undef, undef, 0, 1, 0, undef, 1, undef, undef]);

    # Prepare to be saved.
    $self->_set__dirty(1);

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
    my $self = shift;

    # Make sure the primary uri is up to date.
    my $uri = $self->get_uri;
    $self->_set(['primary_uri'], [$uri])
      unless $self->get_primary_uri eq $uri;

    my ($id, $active, $update_uris) = $self->_get(qw(id _active _update_uri));

    # Start a transaction.
    begin();
    eval {
        if ($id) {
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

        if ($active) {
            $self->_update_uris if $update_uris;
        } else {
            $self->_delete_uris;
        }

        # Save the categories only after the story itself has been saved, so
        # that if it throws an exception, the state of the categories doesn't
        # get out of whack.
        $self->_sync_categories();

        $self->SUPER::save();
        commit();
    };

    if (my $err = $@) {
        rollback();
        rethrow_exception($err);
    }

    return $self;
}

################################################################################

=back

=head1 PRIVATE

=head2 Private Class Methods

=over 4

=cut

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

        my $sth = prepare_ca($sql, undef);
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

    my $sth = prepare_c($sql, undef);
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

    my $sth = prepare_c($sql, undef);
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

    my $sth = prepare_c($sql, undef);
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

        my $sth = prepare_ca($sql, undef);
        execute($sth, $self->_get('version_id'));
        while (my $row = fetch($sth)) {
            $cats->{$row->[0]}->{'primary'} = $row->[1];
        }

        # Write this back in case it has not yet been defined.
        $self->_set([qw(_categories _queried_cats)] => [$cats, 1]);
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

    my $sth = prepare_c($sql, undef);
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

    my $sth = prepare_c($sql, undef);
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

    my $sth = prepare_c($sql, undef);
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
    }, undef);
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

    my $sth = prepare_c($sql, undef);
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

    my $sth = prepare_c($sql, undef);
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

    my $sth = prepare_c($sql, undef);
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

    my $sth = prepare_c($sql, undef);
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

    my $sth = prepare_c($sql, undef);
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

    my $sth = prepare_c($sql, undef);
    execute($sth, $self->_get('id'));
    return $self;
}

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
