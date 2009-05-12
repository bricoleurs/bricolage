package Bric::Biz::Asset;

###############################################################################

=head1 Name

Bric::Biz::Asset - A base class of behaviours that all assets must exhibit. An
asset is anything that goes through workflow

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

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
 $priority        = $asset->get_priority()
 $asset           = $asset->set_priority($priority)

 $site_id     = $asset->get_site_id()
 $asset       = $asset->set_site_id($site_id)

 # User information
 $usr_id      = $asset->get_user__id()
 $modifier    = $asset->get_modifier()

 # Version information
 $vers        = $asset->get_version();
 $vers_id     = $asset->get_version_id();
 $current         = $asset->get_current_version();
 $checked_out = $asset->get_checked_out()

 # Publish info
 $needs_publish = $asset->needs_publish();

 # Expire Data Information
 $asset           = $asset->set_expire_date($date)
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

Asset is the Parent Class for everything that will go through Workflow. It
contains data and actions that are common to all of these objects. Asset holds
information on desks visited by the object, notes associated with the object,
and versioning information. Actions that can be preformed are fork which
prepares an object to be edited in a checked out state, cancel, which cancels
the fork, merge which takes the forked object compares it to the stored main
version and creates a new version and revert which is called on a forked
object which returns the state of the object at a given version id.

A fork will preform a copy in the database keeping the asset id, and version
number the same but will associate a user with the object.

=cut

#==============================================================================#
# Dependencies                         #
#======================================#

#--------------------------------------#
# Standard Dependencies

use strict;
use List::Util qw(first);

#--------------------------------------#
# Programmatic Dependencies

use Bric::App::Event qw(:all);
use Bric::Util::Fault qw(throw_gen throw_mni);
use Bric::Biz::Workflow;
use Bric::Util::Time qw(:all);
use Bric::Util::DBI qw(:all);
use Bric::Util::Pref;
use Bric::Config qw(:all);

#==============================================================================#
# Inheritance                          #
#======================================#

# The parent module should have a 'use' line if you need to import from it.
# use Bric;
use base qw(Bric);

#=============================================================================#
# Function Prototypes                  #
#======================================#

# None

#==============================================================================#
# Constants                            #
#======================================#

use constant DEBUG => 0;
sub RO_FIELDS () { return }
use constant RO_COLUMNS => '';
use constant OBJECT_SELECT_COLUMN_NUMBER => 0;

use constant HAS_MULTISITE => 1;

#==============================================================================#
# Fields                               #
#======================================#

#--------------------------------------#
# Public Class Fields

# Public fields should use 'vars'
#use vars qw();

#--------------------------------------#
# Private Class Fields
my $meths;
my @ord = qw(id version_id name description priority uri cover_date version
             element_type needs_publish publish_status expire_date active
             site_id site);

#--------------------------------------#
# Instance Fields
# None

# This method of Bricolage will call 'use fields' for you and set some permissions.
BEGIN {
    Bric::register_fields({
                        # Public Fields
                        name              => Bric::FIELD_RDWR,
                        description       => Bric::FIELD_RDWR,
                        version           => Bric::FIELD_READ,
                        user__id          => Bric::FIELD_READ,
                        id                => Bric::FIELD_READ,
                        version_id        => Bric::FIELD_READ,
                        current_version   => Bric::FIELD_READ,
                        published_version => Bric::FIELD_RDWR,
                        priority          => Bric::FIELD_RDWR,
                        modifier          => Bric::FIELD_READ,
                        expire_date       => Bric::FIELD_RDWR,
                        checked_out       => Bric::FIELD_READ,
                        workflow_id       => Bric::FIELD_RDWR,
                        desk_id           => Bric::FIELD_READ,
                        site_id           => Bric::FIELD_RDWR,
                        note              => Bric::FIELD_RDWR,

                        # Private Fields
                        _checkin          => Bric::FIELD_NONE,
                        _checkout         => Bric::FIELD_NONE,
                        _cancel           => Bric::FIELD_NONE,
                        _active           => Bric::FIELD_NONE,
                        _delete           => Bric::FIELD_NONE,
                        _notes            => Bric::FIELD_NONE,
                        _got_notes        => Bric::FIELD_NONE,
                        _versions         => Bric::FIELD_NONE,
                        _desk             => Bric::FIELD_NONE,
                        _site             => Bric::FIELD_NONE,
        });
}

#==============================================================================#
# Interface Methods                    #
#======================================#

=head1 Interface

=head2 Constructors

=over 4

=cut

#--------------------------------------#
# Constructors
#------------------------------------------------------------------------------#

sub new {
    my ($pkg, $init) = @_;
    @{$init}{qw(workflow_id desk_id)} = (0, 0);
    $pkg->SUPER::new($init);
}

=item $asset = Bric::Biz::Asset::Business::Story->lookup({ id => $id })

=item $asset = Bric::Biz::Asset::Business::Media->lookup({ id => $id })

=item $asset = Bric::Biz::Asset::Template->lookup({ id => $id })

This will return an asset that matches the ID provided.

B<Throws:>

"Missing required parameter 'id'"

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub lookup {
    my ($pkg, $param) = @_;
    $pkg = ref $pkg || $pkg;
    throw_gen(error => "Missing Required Parameters id or uuid or version_id")
      unless $param->{id} || $param->{version_id} || $param->{uuid}
      || ($param->{alias_id} && $param->{site_id});
    throw_mni(error => 'Must call list on Story, Media, or Template')
      unless $pkg->CAN_DO_LOOKUP;
    # Check the cache.
    my $obj = $pkg->cache_lookup($param);
    return $obj if $obj;

    $param = clean_params($pkg, $param);
    # Lookup can return active and inactive assets.
    delete $param->{active};
    # we generally want the newest version. will use order to get it
    $param->{Order} = 'version';
    $param->{OrderDirection} = 'DESC';
    my $tables =  tables($pkg, $param);
    my ($where, $args) = where_clause($pkg, $param);
    my $order = order_by($pkg, $param);
    my $grp_by = group_by($pkg, $param);
    my $sql = build_query($pkg, $pkg->COLUMNS . $pkg->RO_COLUMNS
                            . join (', ', '', $pkg->GROUP_COLS), $grp_by,
                          $tables, $where, $order, @{$param}{qw(Limit Offset)});
    my $fields = [ 'id', $pkg->FIELDS, 'version_id', $pkg->VERSION_FIELDS,
                   $pkg->RO_FIELDS, 'grp_ids' ];
    my @obj = fetch_objects($pkg, $sql, $fields, scalar $pkg->GROUP_COLS, $args);
    return unless $obj[0];
    return $obj[0];
}

################################################################################

=item (@stories || $stories) = Bric::Biz::Asset::Business::Story->list($params)

=item (@media_objs || $media) = Bric::Biz::Asset::Business::Media->list($params)

=item (@template_objs || $templates) = Bric::Biz::Asset::Business::Template->list($params)

B<See Also:>

=over 4

=item Bric::Biz::Asset::Business::Story->list()

=item Bric::Biz::Asset::Business::Media->list()

=item Bric::Biz::Asset::Business::Template->list()

=back

=cut

sub list {
    my ($pkg, $param) = @_;
    $pkg = ref $pkg || $pkg;
    throw_mni(error => 'Must call list on Story, Media, or Template')
      unless $pkg->CAN_DO_LIST;
    $param = clean_params($pkg, $param);
    my $tables = tables($pkg, $param);
    my ($where, $args) = where_clause($pkg, $param);
    my $order = order_by($pkg, $param);
    my $grp_by = group_by($pkg, $param);
    my $sql = build_query($pkg, $pkg->COLUMNS . $pkg->RO_COLUMNS
                            . join (', ', '', $pkg->GROUP_COLS), $grp_by,
                          $tables, $where, $order, @{$param}{qw(Limit Offset)});
    my $fields = [ 'id', $pkg->FIELDS, 'version_id', $pkg->VERSION_FIELDS,
                   $pkg->RO_FIELDS, 'grp_ids' ];
    my @objs = fetch_objects($pkg, $sql, $fields, scalar $pkg->GROUP_COLS, $args);
    return (wantarray ? @objs : \@objs);
}

=item (@ids||$ids) = Bric::Biz::Asset::Business::Story->list_ids($params)

=item (@ids||$ids) = Bric::Biz::Asset::Business::Media->list_ids($params)

=item (@ids||$ids) = Bric::Biz::Asset::Business::Template->list_ids($params)

B<See Also:>

=over 4

=item Bric::Biz::Asset::Business::Story->list_ids()

=item Bric::Biz::Asset::Business::Media->list_ids()

=item Bric::Biz::Asset::Business::Template->list_ids()

=back

=cut

sub list_ids {
    my ($pkg, $param) = @_;
    $pkg = ref $pkg || $pkg;
    throw_mni(error => 'Must call list on Story, Media, or Template')
      unless $pkg->CAN_DO_LIST_IDS;
    # clean the params
    $param = clean_params($pkg, $param);
    delete $param->{Order};
    my $cols = 'DISTINCT ' . $pkg->ID_COL;
    my $tables =  tables($pkg, $param);
    my ($where, $args) = where_clause($pkg, $param);
    my $order = order_by($pkg, $param);
    # choose the query type, without grp_ids is faster
    my $sql = build_query($pkg, $cols, '', $tables, $where, $order);
    my $select = prepare_ca($$sql, undef);
    my $return = col_aref($select, @$args);
    return wantarray ? @{ $return } : $return;
}

################################################################################

#--------------------------------------#

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

################################################################################

=item my $key_name = Bric::Biz::Asset->key_name()

Returns the key name of this class.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub key_name { 'asset' }

################################################################################

=item my (%priorities || $priorities_href) = $asset->list_priorities()

Returns a list or anonymous array of the priority labels. Each key is the
priority number, and the corresponding value is its label.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub list_priorities {
    my $p = { 1 => 'High',
              2 => 'Medium High',
              3 => 'Normal',
              4 => 'Medium Low',
              5 => 'Low'
            };
    return wantarray ? %$p : $p;
}


################################################################################

=item $meths = Bric::Biz::Asset->my_meths

=item (@meths || $meths_aref) = Bric::Biz::Asset->my_meths(TRUE)

=item my (@meths || $meths_aref) = Bric::Biz::Asset->my_meths(0, TRUE)

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

vals - An anonymous hash of key/value pairs representing the values and display
names to use in a select list.

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub my_meths {
    my ($pkg, $ord, $ident) = @_;

    # We don't got 'em. So get 'em!
    $meths ||= {
              id         => {
                              name     => 'id',
                              get_meth => sub { shift->get_id(@_) },
                              get_args => [],
                              disp     => 'ID',
                              len      => 10,
                              type     => 'short',
                             },
              uuid         => {
                              name     => 'uuid',
                              get_meth => sub { shift->get_uuid },
                              get_args => [],
                              disp     => 'UUID',
                              len      => 36,
                              type     => 'short',
                             },
              version_id => {
                              name     => 'version_id',
                              get_meth => sub { shift->get_version_id(@_) },
                              get_args => [],
                              disp     => 'Version ID',
                              len      => 10,
                              type     => 'short',
                             },
            needs_publish => {
                              name     => 'needs_publish',
                              get_meth => sub { shift->needs_publish(@_) },
                              get_args => [],
                              disp     => 'Needs Publish',
                             },
              name        => {
                              name     => 'name',
                              get_meth => sub { shift->get_name(@_) },
                              get_args => [],
                              set_meth => sub { shift->set_name(@_) },
                              set_args => [],
                              disp     => 'Name',
                              type     => 'short',
                              len      => 256,
                              req      => 1,
                              props    => {   type       => 'text',
                                              length     => 32,
                                              maxlength => 256
                                          }
                             },
              description => {
                              name     => 'description',
                              get_meth => sub { shift->get_description(@_) },
                              get_args => [],
                              set_meth => sub { shift->set_description(@_) },
                              set_args => [],
                              disp     => 'Description',
                              req      => 0,
                              type     => 'short',
                              props    => {   type => 'textarea',
                                              maxlength => 1024,
                                              cols => 40,
                                              rows => 4
                                          }
                             },
              priority    => {
                              name     => 'priority',
                              get_meth => sub { shift->get_priority(@_) },
                              get_args => [],
                              set_meth => sub { shift->set_priority(@_) },
                              set_args => [],
                              disp     => 'Priority',
                              type     => 'short',
                              len      => 1,
                              req      => 1,
                              props    => {   type => 'select',
                                              vals => [[ 1 => 'High'],
                                                       [ 2 => 'Medium High'],
                                                       [ 3 => 'Normal'],
                                                       [ 4 => 'Medium Low'],
                                                       [ 5 => 'Low'],
                                                      ]
                                          }
                             },
              uri         => {
                              name     => 'uri',
                              get_meth => sub { shift->get_uri(@_) },
                              get_args => [],
                              disp     => 'URI',
                              len      => 256,
                              type     => 'short',
                             },
              cover_date  => {
                              name     => 'cover_date',
                              get_meth => sub { shift->get_cover_date(@_) },
                              get_args => [],
                              set_meth => sub { shift->set_cover_date(@_) },
                              set_args => [],
                              search   => 1,
                              disp     => 'Cover Date',
                              len      => 64,
                              req      => 0,
                              type     => 'short',
                              props    => { type => 'date' }
                             },
              version     => {
                              name     => 'version',
                              get_meth => sub { shift->get_version(@_) },
                              get_args => [],
                              disp     => 'Version',
                              len      => 10,
                              type     => 'short',
                             },
              element_type_id => {
                              name     => 'element_type_id',
                              get_meth => sub { shift->get_element_type_id(@_) },
                              get_args => [],
                              set_meth => sub { shift->set_element_type_id(@_) },
                              set_args => [],
                              disp     => 'Element Type ID',
                              len      => 10,
                              req      => 0,
                              type     => 'short',
                             },
              element_type  => {
                              name     => 'element_type',
                              get_meth => sub {
                                  my $a_id = shift->get_element_type_id(@_);
                                  my $a = Bric::Biz::ElementType->lookup({ id => $a_id }) or return;
                                  $a->get_name(); },
                              get_args => [],
                              disp     => 'Element Type',
                              len      => 256,
                              type     => 'short',
                              props    => { type       => 'select' },
                             },
              publish_status => {
                             name     => 'publish_status',
                             get_meth => sub { shift->get_publish_status(@_) },
                             get_args => [],
                             disp     => 'Status',
                             len      => 1,
                             req      => 1,
                             type     => 'short',
                            },
                expire_date => {
                                name     => 'expire_date',
                                get_meth => sub { shift->get_expire_date(@_) },
                                get_args => [],
                                set_meth => sub { shift->set_expire_date(@_) },
                                set_args => [],
                                disp     => 'Expire Date',
                                len      => 64,
                                req      => 0,
                                type     => 'short',
                                props    => { type => 'date' }
                                },
              active     => {
                             name     => 'active',
                             get_meth => sub { shift->is_active(@_) ? 1 : 0 },
                             get_args => [],
                             set_meth => sub { $_[1] ? shift->activate(@_)
                                                 : shift->deactivate(@_) },
                             set_args => [],
                             disp     => 'Active',
                             len      => 1,
                             req      => 1,
                             type     => 'short',
                             props    => { type => 'checkbox' }
                            },
              site_id     => {
                              get_meth => sub { shift->get_site_id(@_) },
                              get_args => [],
                              set_meth => sub { shift->set_site_id(@_) },
                              set_args => [],
                              name     => 'site_id',
                              disp     => 'Site ID',
                              len      => 10,
                              req      => 1,
                              type     => 'short',
                              props    => {}
                             },
              site       => {
                  get_meth => sub {
                      Bric::Biz::Site->lookup({ id => shift->get_site_id(@_) })->get_name
                    },
                  get_args => [],
                  name     => 'site',
                  disp     => 'Site',
                  type     => 'short',
                  props    => { type => 'text' }
              },

             };

    if ($ord) {
        return wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}];
    } elsif ($ident) {
        return wantarray ? $meths->{version_id} : [$meths->{version_id}];
    } else {
        return $meths;
    }
}

#--------------------------------------#

=back

=head2 Public Instance Methods

=over 4

=item $versions = $asset->get_versions

Returns an array or array reference the previous versions of this asset in
order from the first to the current.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_versions {
    my ($self) = @_;
    my $versions = $self->_get('_versions');
    unless ($versions) {
        my $dirty = $self->_get__dirty;
        $versions = $self->list({ id              => $self->get_id,
                                  return_versions => 1,
                                  Order           => 'version' });
        $self->_set({ _versions => $versions });
        $self->_set__dirty($dirty);
    }
    return wantarray ? @$versions : $versions;
}

################################################################################

=item $name = $self->get_name()

Returns the name field from Assets

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $self = $self->set_name()

Sets the name field for Assets

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $site_id = $asset->get_site_id

Returns the ID of the site this asset is a part of.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

################################################################################

=item $site = $asset->get_site

Returns the the site this asset is a part of.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_site {
    my $self = shift;
    my $site;
    unless ($site = $self->_get('_site')) {
        $self->_set(
            ['_site'],
            [ $site = Bric::Biz::Site->lookup({ id => $self->get_site_id }) ]
        );
    }
    return $site;
}

################################################################################

=item $description = $self->get_description()

This returns the description for the asset

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $self = $self->set_description()

This sets the description on the asset, first converting non-Unix line
endings.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub set_description {
    my ($self, $val) = @_;
    $val =~ s/\r\n?/\n/g if defined $val;
    $self->_set( [ 'description' ] => [ $val ]);
}

################################################################################

=item $priority = $asset->get_priority()

This will return the priority that is set upon the asset

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $asset = $asset->set_priority($priority)

This will set the priority for the asset

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $version = $asset->get_version()

Returns the version that this asset represents.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $user_id = $asset->get_user_id()

Returns the user_id of the person to whom the asset is checked out to

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_user_id { shift->_get('user__id') }

################################################################################

=item $user = $asset->get_user()

Returns the Person object of the person to whom the asset is checked out to

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_user {
    my $self = shift;
    return Bric::Biz::Person::User->lookup({ id => $self->_get('user__id') });
}

################################################################################

=item $version_id = $asset->get_version_id()

Returns the database id of the version of this asset.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $current_version = $asset->get_current_version()

Returns the version that is the current one.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $user_id = $asset->get_modifier()

Returns the user id of the person who edited this version of the asset.   If
the asset is checked out it will be the same as the user who checked it out.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $publish_status = $asset->get_publish_status()

returns the publish status flag

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $asset = $asset->set_publish_status($status)

sets the publish status flag.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $needs_publish = $asset->needs_publish()

Compares current_version and published_version from asset table. If the same,
needs_publish returns 0. If different, returns 1.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub needs_publish {
    my $self = shift;
    # Version 0 is never published. Neither is undef, of course.
    my $pub_version = $self->get_published_version or return 1;
    return $self->get_current_version == $pub_version ? 0 : 1;
}

################################################################################

=item $checked_out = $asset->get_checked_out()

Returns the checked out flag

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $self = $story->set_expire_date($expire_date)

Sets the expire date.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to unpack date.

=item *

Unable to format date.

=item *

Incorrect number of args to Bric::_set().

=item *

Bric::set() - Problems setting fields.

=back

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub set_expire_date { $_[0]->_set(['expire_date'], [db_date($_[1])]) }

################################################################################

=item my $expire_date = $story->get_expire_date($format)

Returns expire date.

B<Throws:>

=over 4

=item *

Bric::_get() - Problems retrieving fields.

=item *

Unable to unpack date.

=item *

Unable to format date.

=back

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_expire_date { local_date($_[0]->_get('expire_date'), $_[1]) }

################################################################################

=item $self = $self->set_current_desk($desk_object);

This method takes a desk stamp object and adds it to the asset object

B<Side Effects:>

Adds the asset_grp_id of the desk to grp_ids (unless it was already there).

B<Notes:>

This method only updates the asset's private variables to reflect the new desk
and grp assignment. To truly add or transfer an asset to a desk, refer to the
L<Bric::Biz::Workflow::Parts::Desk|Bric::Biz::Workflow::Parts::Desk> object's
C<accept()> and C<transfer()> methods.

=cut

sub set_current_desk {
    my ($self, $desk) = @_;
    # grp_ids may change as a side effect
    my $dgid = 0;
    if (my $c_desk = $self->get_current_desk) {
        $dgid = $c_desk->get_asset_grp;
    }

    my @grp_ids = ((grep { $_ != $dgid } $self->get_grp_ids), $desk->get_asset_grp);
    $self->_set({grp_ids => \@grp_ids});

    # now set the actual value
    $self->_set([qw(desk_id _desk)] => [$desk->get_id, $desk]);
    return $self;
}

################################################################################

=item $ld = $self->get_current_desk;

This returns the desk stamp of the desk that the object is currently at

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_current_desk {
    my $self = shift;
    my ($id, $desk) = $self->_get(qw(desk_id _desk));
    return $desk if $desk;
    return unless $id; # Desk ID 0 is the same as no desk.
    $desk = Bric::Biz::Workflow::Parts::Desk->lookup({ id => $id });
    $self->_set(['_desk'] => [$desk]);
    return $desk;
}


##############################################################################

=item $self = $self->remove_from_desk

Removes the asset from the current desk.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub remove_from_desk {
    shift->_set([qw(desk_id _desk)], [0]);
}

###############################################################################

=item $id = $asset->get_id()

This returns the id that uniquely identifies this asset.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $id = $asset->get_workflow_id

Returns the workflow ID that this asset is a part of

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

################################################################################

=item $asset = $asset->set_workflow_id( $w_ID );

Sets the workflow that this asset is a member of

B<Side Effects:>

Adds the asset group ID of the workflow to grp_ids unless it was already there.

=cut

sub set_workflow_id {
    my ($self, $workflow_id) = @_;
    $workflow_id ||= 0;

    # grp_ids may change as a side effect
    my $grp_ids = [];
    if (my $wf = $self->get_workflow_object) {
        my $ag_id = $wf->get_asset_grp_id;
        foreach my $gid ($self->get_grp_ids) {
            next if $gid == $ag_id;
            push @$grp_ids, $gid;
        }
    } else {
        $grp_ids = [ grep { $_ != 0 } $self->get_grp_ids ];
    }

    if ($workflow_id) {
        my $wf = Bric::Biz::Workflow->lookup({ id => $workflow_id });
        push @$grp_ids, $wf->get_asset_grp_id;
    } else {
        # Set workflow ID to 0 if there is no associated workflow.
        push @$grp_ids, 0;
    }

    # Now set the workflow ID and the group IDs.
    $self->_set([qw(grp_ids workflow_id)], [$grp_ids, $workflow_id]);
}

################################################################################

=item $workflow_obj = $asset->get_workflow_object();

Returns the workflow object that this asset is associated with

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_workflow_object {
    my ($self) = @_;
    my $w_id = $self->get_workflow_id or return;
    return Bric::Biz::Workflow->lookup({'id' => $w_id});
}

################################################################################

=item $id = $asset->get_desk_id

Returns the ID for the desk the asset is currently on.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

##############################################################################

=item my @grp_ids = $asset->get_grp_ids

=item my $grp_ids_aref = $asset->get_grp_ids

Returns the IDs for all the groups of which the asset is an active member.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> This method overrides C<Bric::get_grp_ids()> in order to add the
site ID to the list of IDs. This works because the site ID corresponds to a
secret group ID.

=cut

sub get_grp_ids {
    my $self = shift;
    return $self->INSTANCE_GROUP_ID unless ref $self;
    my ($gids, $site_id) = $self->_get(qw(grp_ids site_id));
    unshift @$gids, $site_id if $site_id and not $gids->[0] == $site_id;
    return wantarray ? @$gids : $gids;
}

################################################################################

=item $self = $self->cancel

Reverts the actions of a fork with out committing any changes. Deletes row for
the checked out asset.

B<Throws:>

NONE

B<Side Effects:>

Removes the Asset (version) record from the database

B<Notes:>

NONE

=cut

################################################################################

=item  $self->set_note($note);

=item  $self->add_note($note);

Sets the note for this instance of the assset.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> C<add_note()> is deprecated.

=cut

sub add_note { shift->set_note(@_) }

################################################################################

=item my $note = $asset->get_note

Returns the note for this instance of the asset.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

################################################################################

=item my $notes_href = $asset->get_notes;

Returns a hash reference of the notes for the asset. The hash keys are asset
version numbers, and the values are the notes.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_notes {
    my $self  = shift;
    my $notes = $self->_get('_notes');

    unless ($notes) {
        my $table = $self->VERSION_TABLE;
        my $col   = $self->TABLE . '__id';
        my $sel   = prepare_c("
            SELECT version, note
            FROM   $table
            WHERE  $col = ?
            ORDER BY id DESC"
        );
        execute($sel, $self->get_id);
        bind_columns($sel, \my ($version, $note));
        while (fetch($sel)) {
            $notes->{$version} = $note;
        }

        $self->_set(['_notes'] => [$notes] );
    }

    return $notes;
}

################################################################################

=item my $bool = $asset->has_notes

Returns true if the asset has notes in any of its versions, and false if it
does not.

=cut

sub has_notes {
    my $self  = shift;
    if (first { $_ } $self->_get(qw(note _got_notes _notes))) {
        return $self;
    }

    my $table = $self->VERSION_TABLE;
    my $col   = $self->TABLE . '__id';
    my ($got_notes) = row_array(prepare_c("
        SELECT 1
        FROM   $table
        WHERE  $col = ?
               AND note IS NOT NULL
        LIMIT  1
    "), $self->get_id);

    $self->_set(['_got_notes'] => [ $got_notes ]);
    return $got_notes ? $self : undef;
}

=item $asset = $asset->activate()

This will activate a nonactive asset

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub activate {
        my $self = shift;

        $self->_set( { '_active' => 1 } );

        return $self;
}

################################################################################

=item $asset = $asset->deactivate()

This will set the asset to a non active state

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub deactivate {
        my $self = shift;

        $self->_set( { '_active' => 0 } );

        if (EXPIRE_ON_DEACTIVATE) {
           my $tz = Bric::Util::Pref->lookup_val('Time Zone');
           $self->set_expire_date(
               my $now = DateTime->now(time_zone => $tz)->strftime(ISO_8601_FORMAT)
           );
           $self->save;
           my $key = $self->key_name;

           require Bric::Util::Job::Pub;
           my $job = Bric::Util::Job::Pub->new({
               sched_time             => $now,
               user_id                => Bric::App::Session::get_user_id,
               name                   => 'Expire "' . $self->get_name . '"',
               "$key\_instance_id"    => $self->get_version_id,
               priority               => $self->get_priority,
               type                   => 1,
           });
           $job->save;
           log_event('job_new', $job);
         }

        return $self;
}

################################################################################

=item ($asset || undef) = $asset->is_active()

Returns the object if it is active, undef otherwise

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub is_active {
    my $self = shift;

    return $self->_get('_active') ? $self : undef;
}

################################################################################

=item $self = $self->cancel_checkout

Cancels the checkout. Deletes the version instance record.

B<Throws:>

=over 4

=item "Cannot cancel a non checked out asset"

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub cancel_checkout {
    my $self = shift;

    # Make sure it's checked out.
    throw_gen "Cannot cancel a non checked out asset"
      unless $self->_get('checked_out');

    return $self->_set([qw(user__id checked_out _cancel)] => [undef, 0, 1]);
}

##############################################################################

=item $asset = $asset->checkin

Checks the asset in.

B<Throws:>

=over 4

=item *

Cannot checkin non checked out versions.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub checkin {
    my $self = shift;
    throw_gen(error => "Cannot checkin non checked out versions")
      unless $self->_get('checked_out');

    my $version = $self->_get('current_version') + 1;
    $self->_set({
        user__id        => undef,
        version         => $version,
        current_version => $version,
        checked_out     => 0,
        _checkin        => 1
    });

    return $self;
}

################################################################################

=back

=head1 Private


=head2 Private Class Methods

NONE

=head2 Private Instance Methods

NONE

=head2 Private Functions

NONE

=cut

1;

__END__

=head1 Author

=over

=item michael soderstrom <miraso@pacbell.net>

=item Mark Jaroski <jaroskim@who.int>

=item David Wheeler <david@kineticode.com>

=back

=head1 See Also

L<Bric.pm>,L<Bric::Util::Group::AssetVersion>

=cut
