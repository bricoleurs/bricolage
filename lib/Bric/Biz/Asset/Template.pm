package Bric::Biz::Asset::Template;

###############################################################################

=head1 Name

Bric::Biz::Asset::Template - Template assets

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

 # Creation of Objects
 $fa = Bric::Biz::Asset::Template->new( $init )
 $fa = Bric::Biz::Asset::Template->lookup( { id => $id })
 ($fa_list || @fas) = Bric::Biz::Asset::Template->list( $param )
 ($faid_list || @fa_ids) = Bric::Biz::Asset::Template->list_ids( $param )

 # get / set the data that is contained with in
 $fa = $fa->set_data()
 $data = $fa->get_data()

 # get the file name that this will be deployed to
 $file_name = $fa->get_file_name()

 # get / set the date that this will activate
 $date = $fa->get_deploy_date()
 $fa = $fa->set_deploy_date($date)

 # get the output channel that this is associated with
 $output_channel_id = $fa->get_output_channel__id()

 # get the asset type that this is associated with
 $element_type_id = $fa->get_element_type_id()

 # get the category that this is associated with
 $category_id = $fa->get_category_id()

 # Methods Inheriated from Bric::Biz::Asset

 # Class Methods
 $key_name = Bric::Biz::Asset->key_name()
 %priorities = Bric::Biz::Asset->list_priorities()
 $data = Bric::Biz::Asset->my_meths

 # looking up of objects
 ($asset_list || @assets) = Bric::Biz::Asset->list( $param )

 # General information
 $asset       = $asset->get_id()
 $asset       = $asset->set_name($name)
 $name        = $asset->get_name()
 $asset       = $asset->set_description($description)
 $description = $asset->get_description()
 $priority    = $asset->get_priority()
 $asset       = $asset->set_priority($priority)

 # User information
 $usr_id      = $asset->get_user__id()
 $modifier    = $asset->get_modifier()

 # Version information
 $vers        = $asset->get_version();
 $vers_id     = $asset->get_version_id();
 $current     = $asset->get_current_version();
 $checked_out = $asset->get_checked_out()

 # Expire Data Information
 $asset       = $asset->set_expire_date($date)
 $expire_date = $asset->get_expire_date()

 # Desk information
 $desk        = $asset->get_current_desk;
 $asset       = $asset->set_current_desk($desk);

 # Workflow methods.
 $id    = $asset->get_workflow_id;
 $obj   = $asset->get_workflow_object;
 $asset = $asset->set_workflow_id($id);

 # Access note information
 $asset         = $asset->set_note($note);
 my $note       = $asset->get_note;
 my $notes_href = $asset->get_notes()

 # Access active status
 $asset            = $asset->deactivate()
 $asset            = $asset->activate()
 ($asset || undef) = $asset->is_active()

 $asset = $asset->save()

 # returns all the groups this is a member of
 ($grps || @grps) = $asset->get_grp_ids()


=head1 Description

This has changed, it will need to be updated in a bit

=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies

use strict;

#--------------------------------------#
# Programatic Dependencies
use Bric::Biz::Workflow qw(TEMPLATE_WORKFLOW);
use Bric::Util::DBI qw(:all);
use Bric::Util::Grp::AssetVersion;
use Bric::Util::Time qw(:all);
use Bric::Util::Fault qw(:all);
use Bric::Util::Trans::FS;
use Bric::Util::Grp::Template;
use Bric::Biz::ElementType;
use Bric::Biz::Category;
use Bric::Biz::OutputChannel;
use List::Util qw(first);

#==============================================================================#
# Inheritance                          #
#======================================#

use base qw( Bric::Biz::Asset );

#=============================================================================#
# Function Prototypes                  #
#======================================#
# None

#==============================================================================#
# Constants                            #
#======================================#

use constant DEBUG             => 0;
use constant ELEMENT_TEMPLATE  => 1;
use constant CATEGORY_TEMPLATE => 2;
use constant UTILITY_TEMPLATE  => 3;

# constants for the Database
use constant TABLE      => 'template';
use constant VERSION_TABLE => 'template_instance';
use constant ID_COL => 'f.id';
use constant COLS       => qw( name
                               priority
                               description
                               usr__id
                               output_channel__id
                               tplate_type
                               element_type__id
                               category__id
                               file_name
                               current_version
                               published_version
                               deploy_status
                               deploy_date
                               expire_date
                               workflow__id
                               desk__id
                               active
                               site__id);

use constant VERSION_COLS => qw( template__id
                                 version
                                 usr__id
                                 data
                                 file_name
                                 note
                                 checked_out);

use constant FIELDS     => qw( name
                               priority
                               description
                               user__id
                               output_channel__id
                               tplate_type
                               element_type_id
                               category_id
                               file_name
                               current_version
                               published_version
                               deploy_status
                               deploy_date
                               expire_date
                               workflow_id
                               desk_id
                               _active
                               site_id);

use constant VERSION_FIELDS => qw( id
                                   version
                                   modifier
                                   data
                                   file_name
                                   note
                                   checked_out);

use constant GROUP_PACKAGE => 'Bric::Util::Grp::Template';
use constant INSTANCE_GROUP_ID => 33;

use constant CAN_DO_LIST_IDS => 1;
use constant CAN_DO_LIST => 1;
use constant CAN_DO_LOOKUP => 1;

use constant GROUP_COLS => (
    group_concat_sql('m.grp__id'),
    group_concat_sql('c.asset_grp_id'),
    group_concat_sql('w.asset_grp_id'),
);

# the mapping for building up the where clause based on params
use constant WHERE => 'f.id = i.template__id '
  . 'AND fm.object_id = f.id '
  . 'AND m.id = fm.member__id '
  . "AND m.active = '1' "
  . 'AND c.id = f.category__id '
  . 'AND f.workflow__id = w.id';

use constant COLUMNS => join(', f.', 'f.id', COLS) . ', '
            . join(', i.', 'i.id', VERSION_COLS);

use constant OBJECT_SELECT_COLUMN_NUMBER => scalar COLS + 1;

# param mappings for the big select statement
use constant FROM => VERSION_TABLE . ' i';

use constant PARAM_FROM_MAP => {
    _not_simple      => 'template_member fm, member m, '
                      . 'category c, workflow w, ' . TABLE . ' f ',
    grp_id           =>  'member m2, template_member fm2',
    element_key_name => 'element_type e',
    site_id          => 'output_channel oc',
    note             => 'template_instance fi2',
    site             => 'site',
};

PARAM_FROM_MAP->{simple} = PARAM_FROM_MAP->{_not_simple};

use constant PARAM_WHERE_MAP => {
    id                    => 'f.id = ?',
    exclude_id            => 'f.id <> ?',
    active                => 'f.active = ?',
    inactive              => 'f.active = ?',
    site_id               => 'f.output_channel__id = oc.id AND oc.site__id = ?',
    no_site_id            => 'f.output_channel__id = oc.id AND oc.site__id <> ?',
    site                  => 'f.site__id = site.id AND LOWER(site.name) LIKE LOWER(?)',
    workflow__id          => 'f.workflow__id = ?',
    workflow_id           => 'f.workflow__id = ?',
    version_id            => 'i.id = ?',
    _null_workflow_id     => 'f.workflow__id IS NULL',
    element__id           => 'f.element_type__id = ?',
    element_type_id       => 'f.element_type__id = ?',
    element_key_name      => 'f.element_type__id = e.id AND LOWER(e.key_name) LIKE LOWER(?)',
    output_channel_id     => 'f.output_channel__id = ?',
    output_channel__id    => 'f.output_channel__id = ?',
    priority              => 'f.priority = ?',
    deploy_status         => 'f.deploy_status = ?',
    deploy_date_start     => 'f.deploy_date >= ?',
    deploy_date_end       => 'f.deploy_date <= ?',
    expire_date_start     => 'f.expire_date >= ?',
    expire_date_end       => 'f.expire_date <= ?',
    desk_id               => 'f.desk__id = ?',
    name                  => 'LOWER(f.name) LIKE LOWER(?)',
    file_name             => 'LOWER(f.file_name) LIKE LOWER(?)',
    title                 => 'LOWER(f.name) LIKE LOWER(?)',
    description           => 'LOWER(f.description) LIKE LOWER(?)',
    version               => 'i.version = ?',
    published_version     => 'f.published_version = i.version AND i.checked_out = 0',
    deployed_version      => 'f.published_version = i.version AND i.checked_out = 0',
    user__id              => 'i.usr__id = ?',
    user_id               => 'i.usr__id = ?',
    _checked_in_or_out    => 'i.checked_out = '
                           . '( SELECT checked_out '
                           . 'FROM template_instance '
                           . 'WHERE version = i.version '
                           . 'AND template__id = i.template__id '
                           . 'ORDER BY checked_out DESC LIMIT 1 )',
    checked_in            => 'i.checked_out = '
                           . '( SELECT checked_out '
                           . 'FROM template_instance '
                           . 'WHERE version = i.version '
                           . 'AND template__id = i.template__id '
                           . 'ORDER BY checked_out ASC LIMIT 1 )',
    checked_out           => 'i.checked_out = ?',
    _checked_out          => 'i.checked_out = ?',
    _not_checked_out      => "i.checked_out = '0' AND f.id not in "
                           . '(SELECT template__id FROM template_instance '
                           . 'WHERE f.id = template_instance.template__id '
                           . "AND template_instance.checked_out = '1')",
    category_id           => 'f.category__id = ?',
    category_uri          => 'f.category__id = c.id AND '
                           . 'LOWER(c.uri) LIKE LOWER(?))',
    _no_return_versions   => 'f.current_version = i.version',
    grp_id                => "m2.active = '1' AND "
                           . 'm2.grp__id = ? AND '
                           . 'f.id = fm2.object_id AND '
                           . 'fm2.member__id = m2.id',
    simple                => '(LOWER(f.name) LIKE LOWER(?) OR '
                           . 'LOWER(f.file_name) LIKE LOWER(?))',
    note                  => 'fi2.template__id = f.id AND LOWER(fi2.note) LIKE LOWER(?)',
};

use constant PARAM_ANYWHERE_MAP => {
    element_key_name => [ 'f.element_type__id = e.id',
                          'LOWER(e.key_name) LIKE LOWER(?)' ],
    category_uri     => [ 'f.category__id = c.id',
                          'LOWER(c.uri) LIKE LOWER(?))' ],
    grp_id           => [ "m2.active = '1' AND fm2.member__id = m2.id AND f.id = fm2.object_id",
                          'm2.grp__id = ?' ],
    site_id          => [ 'f.output_channel__id = oc.id',
                          'oc.site__id = ?' ],
    no_site_id       => [ 'f.output_channel__id = oc.id',
                          'oc.site__id <> ?' ],
    note             => [ 'fi2.template__id = f.id',
                          'LOWER(fi2.note) LIKE LOWER(?)'],
    site             => [ 'f.site__id = site.id',
                          'LOWER(site.name) LIKE LOWER(?)' ],
};

use constant PARAM_ORDER_MAP => {
    active              => 'f.active',
    inactive            => 'f.active',
    site_id             => 'oc.site__id',
    workflow_id         => 'f.workflow__id',
    workflow__id        => 'f.workflow__id',
    element_id          => 'f.element_type__id',
    element__id         => 'f.element_type__id',
    element_type_id     => 'f.element_type__id',
    output_channel_id   => 'f.output_channel__id',
    output_channel__id  => 'f.output_channel__id',
    priority            => 'f.priority',
    deploy_status       => 'f.deploy_status',
    deploy_date         => 'f.deploy_date',
    expire_date         => 'f.expire_date',
    name                => 'LOWER(f.name)',
    title               => 'LOWER(f.name)',
    file_name           => 'LOWER(i.file_name)',
    category_uri        => 'LOWER(i.file_name)',
    description         => 'LOWER(f.description)',
    version             => 'i.version',
    version_id          => 'i.id',
    user_id             => 'i.usr__id',
    user__id            => 'i.usr__id',
    _checked_out        => 'i.checked_out',
    category_id         => 'f.category__id',
    return_versions     => 'i.version',
};

use constant DEFAULT_ORDER => 'deploy_date';

#==============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields

# None

#--------------------------------------#
# Private Class Fields
my ($meths, @ord, $set_elem, $set_util);

my %tplate_type_strings = ( &ELEMENT_TEMPLATE  => 'Element Template',
                            &CATEGORY_TEMPLATE => 'Category Template',
                            &UTILITY_TEMPLATE  => 'Utility Template'
                          );

my %string_tplate_types = map { $tplate_type_strings{$_} => $_ }
  keys %tplate_type_strings;

#--------------------------------------#
# Instance Fields


BEGIN {
        Bric::register_fields
            ({
              # Public Fields

              # the output channel that this is associated with
              output_channel__id  => Bric::FIELD_READ,

              # The type of template it is.
              tplate_type         => Bric::FIELD_READ,

              # the asset type that this formats
              element_type_id     => Bric::FIELD_READ,

              # the category that this is associated with
              category_id         => Bric::FIELD_READ,

              # the file name as set by the burn system when deployed
              file_name           => Bric::FIELD_READ,

              # Users will insert data into this field and then save will
              # populate the _data_oid field for DB insertion.
              data                => Bric::FIELD_RDWR,

              deploy_status       => Bric::FIELD_RDWR,
              deploy_date         => Bric::FIELD_RDWR,


              # Private Fields
              _active             => Bric::FIELD_NONE,
              _output_channel_obj => Bric::FIELD_NONE,
              _element_type_obj   => Bric::FIELD_NONE,
              _category_obj       => Bric::FIELD_NONE,
              _revert_obj         => Bric::FIELD_NONE
             });
}

#==============================================================================#


=head1 Interface

=head2 Constructors

=over 4

=cut

#--------------------------------------#
# Constructors

#------------------------------------------------------------------------------#

=item $fa = Bric::Biz::Asset::Template->new( $initial_state )

Constructs a new template.

Supported Keys:

=over 4

=item *

description

=item *

data

=item *

deploy_date

=item *

expire_date

=item *

workflow_id

=item *

output_channel - Required unless output channel id passed

=item *

output_channel__id - Required unless output channel object passed

=item *

tplate_type - The type of template it is.

=item *

name - The name of the template. Only used if tplate_type is set to
UTILITY_TEMPLATE.

=item *

element_type - the at object

=item *

element_type_id - the id of the asset type

=item *

category - the category object

=item *

category__id - the category id

=item *

file_type - the type of the template file - this will be used as the extension
for the file_name derived from the element name. Supported file_type values
are those returned as the first value in each array reference in the array
reference returned by C<< Bric::Util::Burner->list_file_types >>.

=back

B<Throws:>

=over 4

=item *

Missing required output channel parameter.

=item *

Missing required parameter 'element_type' or 'element_type_id'.

=item *

Invalid file_type parameter.

=item *

Missing required parameter 'name'

=item *

Invalid tplate_type parameter.

=item *

Missing required parameter 'category' or 'category_id'.

=item *

The template already exists in the output channel.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub new {
    my ($class, $init) = @_;
    my $self = bless {}, $class;
    my @grp_ids = ($class->INSTANCE_GROUP_ID);

    # set active unless we we passed another value
    $init->{_active} = exists $init->{active} ?
      delete $init->{active} ? 1 : 0 : 1;

    $init->{modifier} = $init->{user__id};
    $init->{checked_out} = 1;
    $init->{deploy_status} = 0;
    $init->{priority} ||= 3;

    throw_dp "Cannot create an asset without a site" unless $init->{site_id};
    $init->{grp_ids} = [$init->{site_id}, $self->INSTANCE_GROUP_ID];

    # Check for required output_channel__id.
    throw_dp(error => 'Missing required output channel parameter')
      unless defined $init->{'output_channel'}
        || defined $init->{'output_channel__id'};

    # Lookup the output channel object.
    my $oc;
    if ($oc = $init->{output_channel}) {
        $init->{output_channel__id} = $oc->get_id;
    } else {
        $oc = $init->{output_channel} = Bric::Biz::OutputChannel->lookup({
            id => $init->{output_channel__id},
        }) or throw_dp 'There is no output channel with the ID '
            . $init->{output_channel__id};
    }

    # Get the file type and allowed file types.
    my $file_type  = $init->{file_type};
    my $file_types = Bric::Util::Burner->list_file_types($oc->get_burner);

    # Verify or assign the file type.
    if ($file_type) {
        # Make sure that it's legit.
        unless (first { $_->[0] eq $file_type } @$file_types) {
            throw_dp qq{"$file_type" is not a valid file type in the "}
                   . $oc->get_name . '" output channel';
        }
    } else {
        # Assign the first file extension we can find.
        $init->{file_type} = $file_types->[0][0];
    }

    # Set the site ID and the group IDs.
    my $name;
    if (my $t = $init->{tplate_type}) {
        # The tplate_type parameter has been passed. Check it out.
        if ($t == ELEMENT_TEMPLATE) {
            # It's an element template. Get the name from the element object.
            $name = $set_elem->($init);
        } elsif ($t == CATEGORY_TEMPLATE) {
            # It's a category template. Set the name based on the file type.
            $name = Bric::Util::Burner->cat_fn_for_ext($init->{file_type})
              or throw_dp "Invalid file_type parameter '$init->{file_type}'";
        } elsif ($t == UTILITY_TEMPLATE) {
            $name = $set_util->($init);
        } else {
            throw_dp(error => "Invalid tplate_type parameter '$t'");
        }
    } else {
        # No tplate_type name argument. So figure it out based on context.
        if ($init->{element_type} or defined $init->{element_type_id}
            or $init->{element} or $init->{element__id}
        ) {
            # It's an element template. Get the element info.
            $init->{tplate_type} = ELEMENT_TEMPLATE;
            $name = $set_elem->($init);
        } elsif ($init->{name}) {
            # It's a utility template. Set up the name from the name parameter.
            $init->{tplate_type} = UTILITY_TEMPLATE;
            $name = $set_util->($init);
        } else {
            # It's a category template. Get set up the file name.
            $init->{tplate_type} = CATEGORY_TEMPLATE;
            $name = Bric::Util::Burner->cat_fn_for_ext($init->{file_type})
              or throw_dp "Invalid file_type parameter '$init->{file_type}'";
        }
    }

    if ($init->{category}) {
        $init->{category_id} = $init->{category}->get_id;
        push @grp_ids, $init->{category}->get_asset_grp_id();
    } elsif (defined $init->{category_id}) {
        $init->{category} =
          Bric::Biz::Category->lookup({ id => $init->{category_id} });
        push @grp_ids, $init->{category}->get_asset_grp_id();
    } else {
        throw_dp(error => "Missing required parameter 'category' or 'category_id'");
    }
    my $cat = $init->{category};

    @{$init}{qw(version current_version name)} = (0, 0, $name);
    $self->SUPER::new($init);

    # construct the file name now that the object is in place
    $self->_set(['file_name'],
                [ $self->_build_file_name( $init->{file_type}, $name, $cat,
                                           $init->{output_channel__id},
                                           $init->{tplate_type} ) ]);
    # set the starter grp_ids
    $self->_set({ grp_ids => \@grp_ids });
    return $self;
}

################################################################################

=item $template = Bric::Biz::Template->lookup( $param )

Returns an object that matches the parameters

Supported Keys

=over 4

=item id

A template asset ID.

=item version

Pass to request a specific version otherwise the most current will be
returned.

=back

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

Inherited from Bric::Biz::Asset.

=cut

################################################################################

=item ($fa_list || @fas) = Bric::Biz::Asset::Template->list( $criteria )

Returns a list or anonymous array of Bric::Biz::Asset::Template objects
based on the search parameters passed via an anonymous hash. The supported
lookup keys are:

=over 4

=item name

The name of a template. May use C<ANY> for a list of possible values.

=item title

Same as C<name>.

=item file_name

The file name of a template. May use C<ANY> for a list of possible values.

=item description

Template description. May use C<ANY> for a list of possible values.

=item id

The template ID. May use C<ANY> for a list of possible values.

=item exclude_id

A template ID to exclude from the list. May use C<ANY> for a list of possible
values.

=item version

The template version number. May use C<ANY> for a list of possible values.

=item version_id

The ID of a version of a template. May use C<ANY> for a list of possible
values.

=item active

Defaults to true

=item user_id

If defined will return the versions checked out to the user with this
id. Otherwise , unless C<checked_out> is passed, it will return the most
current non-checked out versions.

=item site_id

Returns a list of templates associated with a given site ID. May use C<ANY>
for a list of possible values.

=item site

Returns a list of templates associated with a given site name. May use C<ANY>
for a list of possible values.

=item category_id

Returns a list of templates in the category represented by a category ID. May
use C<ANY> for a list of possible values.

=item deployed_version

Returns the versions of the templates as they were last deployed. The
C<checked_out> parameter will be ignored if this parameter is passed a true
value.

=item published_version

An alias for C<deployed_version>.

=item category_uri

Returns a list of templates with a given category URI. May use C<ANY> for a
list of possible values.

=item checked_out

Indicates whether to list templates that are checked out or not. If "0", then
only non-checked out templates will be returned. If "1", then only checked-out
templates will be returned. If "all", then the checked_out attributed will be
ignored (unless the C<user__id> parameter is passed).

=item checked_in

If passed a true value, this parameter causes the checked in version of the
most current version of the template to be returned. When a template is
checked out, there are two instances of the current version: the one checked
in last, and the one currently being edited. When the C<checked_in> parameter
is a true value, then the instance last checked in is returned, rather than
the instance currently checked out. This is useful for users who do not
currently have a template checked out and wish to see the template as of the
last check in, rather than as currently being worked on in the current
checkout. If a template is not currently checked out, this parameter has no
effect.

=item return_versions

Will return all the versions of the given templates

=item element_type_id

Returns a list of templates associated with a given element type ID. May use
C<ANY> for a list of possible values.

=item element_key_name

Returns a list of templates associated with an element with the given key
name. May use C<ANY> for a list of possible values.

=item note

Returns templates with a note matching the value associated with any of their
versions. May use C<ANY> for a list of possible values.

=item workflow_id

Return a list of templates in the workflow represented by the workflow ID. May
use C<ANY> for a list of possible values.

=item desk_id

Returns a list of templates on a desk with the given ID. May use C<ANY> for a
list of possible values.

=item output_channel_id

Returns a list of templates associated with a given output channel ID. May use
C<ANY> for a list of possible values.

=item priority

Returns a list of templates associated with a given priority value. May use
C<ANY> for a list of possible values.

=item deploy_status

Boolean value indicating whether to return deployed or undeployed templates.

=item deploy_date_start

Returns a list of templates last deployed on or after a given date/time.

=item deploy_date_end

Returns a list of templates last deployed on or before a given date/time.

=item expire_date_start

Returns a list of templates with a expire date on or after a given date/time.

=item expire_date_end

Returns a list of templates with a expire date on or before a given date/time.

=item grp_id

Returns a list of templates that are members of the group with the specified
group ID. May use C<ANY> for a list of possible values.

=item active

Boolean indicating whether to return active or inactive templates.

=item simple

Triggers a single OR search that hits name and file name.

=item Order

A property name or array reference of property names to order by.

=item OrderDirection

The direction in which to order the records, either "ASC" for ascending (the
default) or "DESC" for descending. This value is applied to the property
specified by the C<Order> parameter, and may also be an array reference. If no
value is supplied for any C<Order> property name, it will default to
ascending.

=item Limit

A maximum number of objects to return. If not specified, all objects that
match the query will be returned.

=item Offset

The number of objects to skip before listing the remaining objcts or the
number of objects specified by C<Limit>.

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:>

Inherited from Bric::Biz::Asset.

=cut

#--------------------------------------#

=back

=head2 Destructors

=over 4

=item $template->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

=back

=cut

sub DESTROY {
        # This method should be here even if its empty so that we don't waste time
        # making Bricolage's autoload method try to find it.
}

#--------------------------------------#

=head2 Public Class Methods

=over 4

=item ($ids || @ids) = Bric::Biz::Asset::Template->list_ids($param)

Returns an unordered list or array reference of template object IDs that match
the criteria defined. The criteria are the same as those for the C<list()>
method except for C<Order> and C<OrderDirection>, which C<list_ids()> ignore.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

Inherited from Bric::Biz::Asset.

=cut


################################################################################

=item my $key_name = Bric::Biz::Asset::Template->key_name()

Returns the key name of this class.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub key_name { 'template' }

################################################################################

=item $meths = Bric::Biz::Asset::Template->my_meths

=item (@meths || $meths_aref) = Bric::Biz::Asset::Formattiong->my_meths(TRUE)

=item my (@meths || $meths_aref) = Bric::Biz:::Asset::Template->my_meths(0, TRUE)

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
    push @ord, qw(file_name deploy_date output_channel tplate_type category
                  category_name), pop @ord;

    $meths->{file_name} = {
        name     => 'file_name',
        get_meth => sub { shift->get_file_name(@_) },
        get_args => [],
        set_meth => sub { shift->set_file_name(@_) },
        set_args => [],
        disp     => 'File Name',
        len      => 256,
        req      => 0,
        type     => 'short',
        props    => {
            type      => 'text',
            length    => 32,
            maxlength => 256
        }
    };

    $meths->{deploy_date} = {
        name     => 'deploy_date',
        get_meth => sub { shift->get_deploy_date(@_) },
        get_args => [],
        set_meth => sub { shift->set_deploy_date(@_) },
        set_args => [],
        disp     => 'Deploy Date',
        len      => 64,
        req      => 0,
        type     => 'short',
        props    => { type => 'date' }
    };

    $meths->{output_channel} = {
        name     => 'output_channel',
        get_meth => sub { shift->get_output_channel(@_) },
        get_args => [],
        set_meth => sub { shift->set_output_channel(@_) },
        set_args => [],
        disp     => 'Output Channel',
        len      => 64,
        req      => 0,
        type     => 'short',
    };

    $meths->{tplate_type} = {
        name     => 'tplate_type',
        get_meth => sub { shift->get_tplate_type(@_) },
        get_args => [],
        disp     => 'Template Type',
        len      => 1,
        req      => 1,
        type     => 'short',
        props    => {
            type => 'select',
            vals => [
                [ &ELEMENT_TEMPLATE  => 'Element'  ],
                [ &CATEGORY_TEMPLATE => 'Category' ],
                [ &UTILITY_TEMPLATE  => 'Utility'  ],
            ]
        }
    };

    $meths->{output_channel_name} = {
        get_meth => sub { shift->get_output_channel_name(@_) },
        get_args => [],
        name => 'output_channel_name',
        disp => 'Output Channel',
        len  => 64,
        req  => 1,
        type => 'short',
    };

    $meths->{category} = {
        get_meth => sub { shift->get_category(@_) },
        get_args => [],
        set_meth => sub { shift->set_category(@_) },
        set_args => [],
        name     => 'category',
        disp     => 'Category',
        len      => 64,
        req      => 1,
        type     => 'short',
    };

    $meths->{category_name} = {
        get_meth => sub { shift->get_category(@_)->get_name },
        get_args => [],
        name     => 'category_name',
        disp     => 'Category Name',
        len      => 64,
        req      => 1,
        type     => 'short',
    };

    $meths->{category_uri} = {
        get_meth => sub { shift->get_category(@_)->get_uri },
        get_args => [],
        name     => 'category_uri',
        disp     => 'Category URI',
        len      => 64,
        req      => 1,
        type     => 'short',
    };

    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}];
}

################################################################################

=item my $tplate_type = Bric::Biz::Asset::Template->get_tplate_type_code($str)

Returns the template type number for a string value as returned by
C<get_tplate_type_string()>.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_tplate_type_code {
    $string_tplate_types{$_[1]}
}

################################################################################

=item my $wf_type = Bric::Biz::Asset::Template->workflow_type

Returns the value of the Bric::Biz::Workflow C<TEMPLATE_WORKFLOW> constant.

=cut

sub workflow_type { TEMPLATE_WORKFLOW }

##############################################################################

=back

=head2 Public Instance Methods

=over 4

=item $template = $template->set_deploy_date($date)

=item $template = $template->set_cover_date($date)

Sets the deployment date for this template

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub set_deploy_date {
    my $self = shift;
    my $date = db_date(shift);
    my $deploy_date = $self->_get('deploy_date');

    unless (defined $deploy_date and $date eq $deploy_date) {
        $self->_set(['deploy_date'], [$date]);
    }

    return $self;
}

*set_cover_date = \&set_deploy_date;

################################################################################

=item $date = $template->get_deploy_date()

=item $date = $template->get_cover_date()

Returns the deploy date set upon this template

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_deploy_date { local_date($_[0]->_get('deploy_date'), $_[1]) }

*get_cover_date = \&get_deploy_date;

################################################################################

=item $status = $template->get_deploy_status()

=item $template = $template->get_publish_status()

Returns the deploy status of the template asset

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

this will return the deploy date

=cut

sub get_publish_status { $_[0]->_get('deploy_status') }

################################################################################

=item $template = $template->set_deploy_status()

=item $template = $template->set_publish_status()

sets the deploy status for this template

B<Throws:>

NONE

B<Side Effect:>

NONE

B<Notes:>

This is really the deploy date

=cut

sub set_publish_status {
    my $self = shift;
    my ($status) = @_;

    if ($status ne $self->get_deploy_status) {
        $self->set_deploy_status($status);
    }

    return $self;
}

################################################################################

=item $uri = $template->get_uri

Returns the URI for the template. This differs from the file_name in that the
latter uses the semantics of your local file system.w

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_uri { Bric::Util::Trans::FS->dir_to_uri($_[0]->get_file_name) }

################################################################################

=item $file_name = $template->get_file_name()

Returns the file path of this template.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $name = $template->get_output_channel_name;

Return the name of the output channel.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_output_channel_name {
    my $self = shift;
    my $oc_obj = $self->get_output_channel;

    return unless $oc_obj;

    return $oc_obj->get_name;
}

################################################################################

=item $oc = $template->get_output_channel;

=item $oc = $template->get_primary_oc;

Return the output channel associated with this Template asset. The
C<get_primary_oc()> alias is provided to be compatible with business assets.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_output_channel {
    my $self = shift;
    my $dirty = $self->_get__dirty;
    my ($oc_id, $oc_obj) = $self->_get('output_channel__id',
                                       '_output_channel_obj');

    return unless $oc_id;

    unless ($oc_obj) {
        $oc_obj = Bric::Biz::OutputChannel->lookup({'id' => $oc_id});
        $self->_set(['_output_channel_obj'], [$oc_obj]);

        # Restore the original dirty value.
        $self->_set__dirty($dirty);
    }

    return $oc_obj;
}
{
    no strict 'refs';
    *get_primary_oc = \&get_output_channel;
}

##############################################################################

=item my $tplate_type_string = $template->get_tplate_type_string

Returns a the stringified name of the template type attribute.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_tplate_type_string {
    $tplate_type_strings{$_[0]->_get('tplate_type') }
}

################################################################################

=item $name = $template->get_element_name;

Return the name of the element associated with this object.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut


sub get_element_name {
    my $self = shift;
    my $at_obj = $self->get_element_type or return;
    return $at_obj->get_name;
}

################################################################################

=item $key_name = $template->get_element_key_name;

Return the key name of the element associated with this object.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut


sub get_element_key_name {
    my $self = shift;
    my $at_obj = $self->get_element_type or return;
    return $at_obj->get_key_name;
}

################################################################################

=item $at_obj = $template->get_element_type

Return the element type object for this template asset.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> C<get_element()> has been deprecated in favor of this method.

=cut

sub get_element_type {
    my $self = shift;
    my ($at_id, $at_obj) = $self->_get('element_type_id', '_element_type_obj');

    unless ($at_obj) {
        return unless $at_id;
        $at_obj = Bric::Biz::ElementType->lookup({'id' => $at_id});
        my $dirty = $self->_get__dirty;
        $self->_set(['_element_type_obj'] => [$at_obj]);

        # Restore the original dirty value.
        $self->_set__dirty($dirty);
    }

    return $at_obj;
}

sub get_element {
    require Carp
        && carp(__PACKAGE__ . '::get_element is deprecated. Use get_element_type() instead');
    shift->get_element_type(@_);
}

################################################################################

=item $fa = $fa->set_category_id($id)

Sets the category id for this template asset

B<Throws:>

=over 4

=item *

The template already exists in the output channel.

=back

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub set_category_id {
    my ($self, $id) = @_;
    return $self unless $id != $self->get_category_id;
    my $old_agrp_id = $self->get_category->get_asset_grp_id;
    my $cat = Bric::Biz::Category->lookup({ id => $id });
    my @grp_ids = (
        grep({ $_ != $old_agrp_id} $self->get_grp_ids),
        $cat->get_asset_grp_id
    );
    $self->_set([qw(category_id _category_obj grp_ids)] =>
                [$id, $cat, \@grp_ids]);
    $self->_set(['file_name'] => [ $self->_build_file_name ]);
}

################################################################################

=item $fa = $fa->get_cagetory_id

Get the category ID for this template asset.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $fa = $fa->get_category

Returns the category object that has been associated with this template asset.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_category {
        my ($self) = @_;

        return $self->_get_category_object();
}

################################################################################

=item $fa = $fa->get_cagetory_path

Returns the path from the category

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_category_path {
        my ($self) = @_;

        my $cat = $self->_get_category_object || return;

        return $cat->ancestry_path;
}

################################################################################

=item $fa = $fa->get_cagetory_name

Get the category name of the category object associated with this
template asset.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_category_name {
    my ($self) = @_;

    my $cat = $self->_get_category_object || return;

    return $cat->get_name;
}

################################################################################

=item $template = $template->set_data( $data )

Set the main data for the template asset.   In future incarnations 
there might be more data points that surround this, but not for now.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $data = $template->get_data()

Returns the chunk of text that makes up this template.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $format = $format->checkout($param);

This will create a flag to add a new record to the instance table

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub checkout {
        my ($self, $param) = @_;

        # make sure that this version is the most current
        unless ($self->_get('version') == $self->_get('current_version') ) {
            throw_gen(error => "Unable to checkout old_versions");
        }
        # Make sure that the object is not already checked out
        if (defined $self->_get('user__id')) {
            throw_gen(error => "Already Checked Out");
        }
        unless (defined $param->{'user__id'}) {
            throw_gen(error => "Must be checked out to users");
        }

        $self->_set({'user__id'    => $param->{'user__id'} ,
                     'modifier'    => $param->{'user__id'},
                     'version_id'  => undef,
                     'checked_out' => 1,
                     'note'        => undef,
                    });

        return $self;
}

################################################################################

=item ($fa || undef) = $fa->is_current()

Return whether this is the most current version or not.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub is_current {
    my ($self) = @_;

    return ($self->_get('version') == $self->_get('current_version'))
                ? $self : undef;
}

#------------------------------------------------------------------------------#

=item $fa = $fa->cancel()

This cancles a checkout.   This will delete the record from the 
database

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub cancel {
    my ($self) = @_;
    my $dirty = $self->_get__dirty;

    if (not defined $self->get_user__id) {
        # this is not checked out, it cannot be deleted
        my $msg = 'Cannot cancel an asset that is not checked out';
        throw_ap(error => $msg);
    }

    $self->_set(['_cancel'], [1]);
    # Restore the original dirty value.
    $self->_set__dirty($dirty);

    return $self;
}

################################################################################

=item $fa = $fa->revert()

This will take an older version and copy its data to this version

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut


sub revert {
    my ($self, $version) = @_;

    unless ($self->_get('checked_out')) {
        throw_gen "May not revert a non checked out version";
    }

    # Clear out the cache and look up the old version.
    $self->uncache_me;
    my $revert_obj = __PACKAGE__->lookup({
        id              => $self->_get_id,
        version         => $version
    }) or throw_gen "The requested version does not exist";

    $self->_set(['data'], [$revert_obj->get_data]);

    # Make sure the current version is cached.
    return $self->cache_me;
}

################################################################################

=item $fa = $fa->save()

this will update or create a record in the database

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub save {
    my ($self) = @_;

    # Handle a cancel.
    my ($id, $vid, $cancel, $ver) =
      $self->_get(qw(id version_id _cancel version));

    # Only update/insert this object if some of our fields are dirty.
    if ($self->_get__dirty) {
        if ($self->get_id) {
            # make any necessary updates to the Main table
            $self->_update_template();

            # Update or insert depending on if we have an ID.
            if ($self->get_version_id) {
                if ($cancel) {
                    if (defined $id and defined $vid) {
                        $self->_delete_instance();
                        $self->_delete_template() if $ver == 0;
                        $self->_set(['_cancel'], [undef]);
                    }
                    return $self;
                }
                $self->_update_instance();
            } else {
                $self->_insert_instance();
            }
        } else {
            # This is Brand new insert both Tables
            $self->_insert_template();
            $self->_insert_instance();
        }
    }

    # Call the parents save method
    $self->SUPER::save();

    $self->_set__dirty(0);

    return $self;
}


#=============================================================================#

=back

=head2 Private

=over 4


################################################################################

=back

=head2 Private Instance Methods

=over 4

=item $cat_obj = $self->_get_category_object()

Returns the category object that this is associated with

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_category_object {
    my $self = shift;
    my $dirty = $self->_get__dirty;
    my ($cat_id, $cat_obj) = $self->_get('category_id', '_category_obj');

    return unless defined $cat_id;

    unless ($cat_obj) {
        $cat_obj = Bric::Biz::Category->lookup({ id => $cat_id });
        $self->_set(['_category_obj'], [$cat_obj]);

        # Restore the original dirty value.
        $self->_set__dirty($dirty);
    }

    return $cat_obj;
}

################################################################################

=item $self = $self->_insert_template();

Inserts a row into the template table that represents a new template Asset.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _insert_template {
        my ($self) = @_;

        my $sql = 'INSERT INTO '. TABLE .' (id,'.join(',', COLS).') '.
                  "VALUES (${\next_key(TABLE)},".join(',', ('?') x COLS).')';

        my $sth = prepare_c($sql, undef);
        execute($sth, $self->_get(FIELDS));

        $self->_set(['id'], [last_key(TABLE)]);

        # And finally, register this person in the "All Templates" group.
        $self->register_instance(INSTANCE_GROUP_ID, GROUP_PACKAGE);

        return $self;
}

################################################################################

=item $self = $self->_insert_instance()

Inserts a row associated with an instance of a template asset

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
                                ' (id, '.join(', ', VERSION_COLS) .') '.
                                "VALUES (${\next_key(VERSION_TABLE)}, " . 
                                        join(',',('?') x VERSION_COLS) . ')';

        my $sth = prepare_c($sql, undef);
        execute($sth, $self->_get(VERSION_FIELDS));

        $self->_set(['version_id'], [last_key(VERSION_TABLE)]);

        return $self;
}

################################################################################

=item $self = $self->_update_template()

Updates the template table

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _update_template {
    my ($self) = @_;

    my @cols   = COLS;
    my @fields = FIELDS;
    unless ($self->_get('_checkin')) {
        # Do not update current_version unless we're checking in.
        @cols   = grep { $_ ne 'current_version' } @cols;
        @fields = grep { $_ ne 'current_version' } @fields;
    }

    my $sql = 'UPDATE ' . TABLE .
              ' SET ' . join(', ', map {"$_ = ?" } @cols) .
              ' WHERE id = ?';

    my $sth = prepare_c($sql, undef);
    execute($sth, $self->_get(@fields), $self->_get('id'));

    return $self;
}

################################################################################

=item $self = $self->_update_instance()

Updates the row related to the instance of the template asset

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _update_instance {
        my ($self) = @_;

        my $sql = 'UPDATE ' . VERSION_TABLE .
                                ' SET ' . join(', ', map {"$_=?" } VERSION_COLS) .
                                ' WHERE id=? ';

        my $sth = prepare_c($sql, undef);

        execute($sth, $self->_get(VERSION_FIELDS), $self->get_version_id);

        return $self;
}

################################################################################

=item $self = $self->_delete_template()

Removes the row associated with this template asset from the database

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _delete_template {
        my ($self) = @_;

        my $sql = 'DELETE FROM ' . TABLE . ' WHERE id=?';

        my $sth = prepare_c($sql, undef);

        execute($sth, $self->get_id);

        return $self;
}

################################################################################

=item $self = $self->_delete_instance()

Removes the instance specific row from the database

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _delete_instance {
    my ($self) = @_;
    my $sql = 'DELETE FROM ' . VERSION_TABLE . ' WHERE id=? ';
    my $sth = prepare_c($sql, undef);
    execute($sth, $self->_get('version_id'));
    return $self;
}

=item my $uri = $self->_build_file_name($file_type, $name, $cat);

Builds the file name for a template. If $file_type, $name, or $cat are not
passed, they'll be fetched (or for $file_type, computed) from $self.

B<Throws:>

=over 4

=item *

The template already exists in the output channel.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _build_file_name {
    my ($self, $file_type, $name, $cat, $oc_id, $tplate_type) = @_;

    # compute file_type from file_name if not set
    if ($file_type) {
      $file_type = ".$file_type";
  } else {
      my $old = $self->_get('file_name');
      ($file_type) = $old =~ /(\.[^.]+)$/;
    }

    # Get the name and category object.
    $cat  ||= $self->_get_category_object
      or throw_dp(error => "Templates must be associated with a category");
    $name ||= $self->_get('name');
    $oc_id ||= $self->_get('output_channel__id');
    $tplate_type ||= $self->_get('tplate_type');

    # Mangle the file name.
    my $file = lc $name;
    my $kn   = $self->get_element_key_name;
    $file    =~ s/\Q$file_type\E$// unless defined $kn && $kn eq $file;
    $file    =~ y/a-z0-9/_/cs;
    $file   .= $file_type if $tplate_type != CATEGORY_TEMPLATE
      or Bric::Util::Burner->cat_fn_has_ext($file);

    # Create the file name.
    my $fn = Bric::Util::Trans::FS->cat_dir(($cat ? $cat->ancestry_path : ()),
                                            $file);
    # Make sure that the filename isn't already in use for this output channel.
    my @existing = (
        $self->list_ids({
            file_name          => $fn,
            checked_out        => 'all',
            output_channel__id => $oc_id
        }),
        $self->list_ids({
            file_name          => $fn,
            checked_out        => 'all',
            output_channel__id => $oc_id,
            active             => 0,
        })
    );
    throw_dp(error => "The template '$fn' already exists in output " .
             "channel '" . $self->get_output_channel_name . "'")
      if @existing;

    # If we get here, just return the file name.
    return $fn;
};

=back

=head2 Private Functions

=over 4

=item my $name = $set_elem->($init)

Sets the name of the template based on an element association.

B<Throws:>

=over 4

=item *

Missing required parameter 'element' or 'element_type_id'.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$set_elem = sub {
    my $init = shift;

    if (my $et = $init->{element_type} ||= delete $init->{element}) {
        $init->{element_type_id} = $et->get_id;
    } elsif (defined $init->{element_type_id}
             || defined $init->{element_id}
             || defined $init->{element__id}
    ) {
        $init->{element_type} = Bric::Biz::ElementType->lookup({
            id => $init->{element_type_id}
                  ||= delete $init->{element_id}
                  || delete $init->{element__id}
        });
    } else {
        throw_dp(error => "Missing required parameter 'element_type' or " .
                 "'element_type_id'");
    }

    return $init->{element_type}->get_key_name;
};

=item my $name = $set_util->($init)

Sets the name of the template as a utility template, based on the C<name>
parameter.

B<Throws:>

=over 4

=item *

Missing required parameter 'name'.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

$set_util = sub {
    my $init = shift;
    my $name = delete $init->{name}
      or throw_dp(error => "Missing required parameter 'name'");
    return $name;
};

1;
__END__

=back

=head1 Notes

NONE

=head1 Author

michael soderstrom - miraso@pacbell.net

=head1 See Also

L<Bric>, L<Bric::Biz::Asset>

=cut
