package Bric::Biz::Asset;
###############################################################################

=head1 NAME

Bric::Biz::Asset - A base class of behaviours that all assets must exhibit. An
asset is anything that goes through workflow

=head1 VERSION

$Revision: 1.25.2.8 $

=cut

our $VERSION = (qw$Revision: 1.25.2.8 $ )[-1];

=head1 DATE

$Date: 2003-03-21 01:15:22 $

=head1 SYNOPSIS

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

 # Desk stamp information
 ($desk_stamp_list || @desk_stamps) = $asset->get_desk_stamps()
 $desk_stamp                        = $asset->get_current_desk()
 $asset                             = $asset->set_current_desk($desk_stamp)

 # Workflow methods.
 $id    = $asset->get_workflow_id;
 $obj   = $asset->get_workflow_object;
 $asset = $asset->set_workflow_id($id);

 # Access note information
 $asset                 = $asset->add_note($note)
 ($note_list || @notes) = $asset->get_notes()

 # Access active status
 $asset            = $asset->deactivate()
 $asset            = $asset->activate()
 ($asset || undef) = $asset->is_active()

 $asset = $asset->save()

 # returns all the groups this is a member of
 ($grps || @grps) = $asset->get_grp_ids()

=head1 DESCRIPTION

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

#--------------------------------------#
# Programmatic Dependencies              

use Bric::Util::Fault::Exception::GEN;
use Bric::Util::Fault::Exception::MNI;
use Bric::Biz::Workflow;
use Bric::Util::Time qw(:all);
use Bric::Util::DBI qw(:all);

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
my @ord = qw(id name description priority uri cover_date  version element needs_publish publish_status expire_date active);
my $gen = 'Bric::Util::Fault::Exception::GEN';

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
                        modifer           => Bric::FIELD_READ,
                        expire_date       => Bric::FIELD_RDWR,
                        checked_out       => Bric::FIELD_READ,
                        workflow_id       => Bric::FIELD_RDWR,
                        desk_id           => Bric::FIELD_READ,

                        # Private Fields
                        _checkin          => Bric::FIELD_NONE,
                        _checkout         => Bric::FIELD_NONE,
                        _cancel           => Bric::FIELD_NONE,
                        _active           => Bric::FIELD_NONE,
                        _delete           => Bric::FIELD_NONE,
                        _notes            => Bric::FIELD_NONE,
                        _desk_stamps      => Bric::FIELD_NONE,
                        _attribute_object => Bric::FIELD_NONE,
                        _attr_cache       => Bric::FIELD_NONE,
                        _update_attrs     => Bric::FIELD_NONE,
                        _versions         => Bric::FIELD_NONE,
                        _desk             => Bric::FIELD_NONE,
                        _workflow_id      => Bric::FIELD_NONE
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

=item $asset = Bric::Biz::Asset::Business::Story->lookup({ id => $id })

=item $asset = Bric::Biz::Asset::Business::Media->lookup({ id => $id })

=item $asset = Bric::Biz::Asset::Formatting->lookup({ id => $id })

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
    die $gen->new({ msg => "Missing Required Parameters id or version_id" })
      unless $param->{id} || $param->{version_id};
    die Bric::Util::Fault::Exception::MNI->new
      ({ msg => 'Must call list on Story, Media, or Formatting'})
      unless $pkg->CAN_DO_LOOKUP;
    $param = clean_params($pkg, $param);
    # we don't care about checked out state for lookup
    delete $param->{_checked_out};
    # but we do want the newest version. will use order to get it
    $param->{Order} = 'version';
    $param->{OrderDirection} = 'DESC';
    my $tables =  tables($pkg, $param);
    my ($where, $args) = where_clause($pkg, $param);
    my $order = order_by($pkg, $param);
    my $sql = build_query_with_unions($pkg, $pkg->COLUMNS, $tables, $where,
                                      $order);
    my $fields = [ 'id', $pkg->FIELDS, 'version_id', $pkg->VERSION_FIELDS,
                   'grp_ids' ];
    # Send so many arguments as we have relations
    $args = [ (@$args) x @{$pkg->RELATIONS} ];
    my @obj = fetch_objects( $pkg, $sql, $fields, $args, $param->{Limit},
                             $param->{Offset});
    return unless $obj[0];
    return $obj[0];
}

################################################################################

=item (@stories || $stories) = Bric::Biz::Asset::Business::Story->list($params)

=item (@media_objs || $media) = Bric::Biz::Asset::Business::Media->list($params)

=item (@template_objs || $templates) = Bric::Biz::Asset::Business::Formatting->list($params)

B<See Also:>

=over 4

=item Bric::Biz::Asset::Business::Story->list()

=item Bric::Biz::Asset::Business::Media->list()

=item Bric::Biz::Asset::Business::Formatting->list()

=back

=cut

sub list {
    my ($pkg, $param) = @_;
    $pkg = ref $pkg || $pkg;
    die Bric::Util::Fault::Exception::MNI->new
      ({ msg => 'Must call list on Story, Media, or Formatting'})
      unless $pkg->CAN_DO_LIST;
    $param = clean_params($pkg, $param);
    my $tables = tables($pkg, $param);
    my ($where, $args) = where_clause($pkg, $param);
    my $order = order_by($pkg, $param);
    my $fields = [ 'id', $pkg->FIELDS, 'version_id', $pkg->VERSION_FIELDS,
                   'grp_ids' ];
    my $sql = build_query_with_unions($pkg, $pkg->COLUMNS, $tables, $where,
                                      $order);
    # Send so many arguments as we have relations
    $args = [ (@$args) x @{$pkg->RELATIONS} ];
    my @objs = fetch_objects($pkg, $sql, $fields, $args, $param->{Limit},
                             $param->{Offset});
    return unless $objs[0];
    return (wantarray ? @objs : \@objs);
}

=item (@ids||$ids) = Bric::Biz::Asset::Business::Story->list_ids($params)

=item (@ids||$ids) = Bric::Biz::Asset::Business::Media->list_ids($params)

=item (@ids||$ids) = Bric::Biz::Asset::Business::Formatting->list_ids($params)

B<See Also:>

=over 4

=item Bric::Biz::Asset::Business::Story->list_ids()

=item Bric::Biz::Asset::Business::Media->list_ids()

=item Bric::Biz::Asset::Business::Formatting->list_ids()

=back

=cut

sub list_ids {
    my ($pkg, $param) = @_;
    $pkg = ref $pkg || $pkg;
    die Bric::Util::Fault::Exception::MNI->new
      ({ msg => 'Must call list on Story, Media, or Formatting'})
      unless $pkg->CAN_DO_LIST_IDS;
    # clean the params
    $param = clean_params($pkg, $param);
    delete $param->{Order};
    my $cols = $pkg->ID_COL;
    my $tables =  tables($pkg, $param);
    my ($where, $args) = where_clause($pkg, $param);
    my $order = order_by($pkg, $param);
    # choose the query type, without grp_ids is faster
    my $sql;
    if ( $param->{grp_id} ) {
        $sql = build_query_with_unions($pkg, $cols, $tables, $where, $order);
        $args = [ @$args, @$args, @$args, @$args ];
    } else {
        $sql = build_query($cols, $tables, $where, $order);
    }
    my $select = prepare_ca($sql, undef, DEBUG);
    my $return = col_aref($select, @$args);
    return unless $return->[0];
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
    return if $ident;

    # Return 'em if we got em.
    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}]
      if $meths;

    # We don't got 'em. So get 'em!
    $meths = {
              id         => {
                              name     => 'id',
                              get_meth => sub { shift->get_id(@_) },
                              get_args => [],
                              disp     => 'ID',
                              len      => 10,
                              type     => 'short',
                             },
                  needs_publish => {
                  name     => 'needs_publish',
                  get_meth => sub { my $a=shift;
                                                                        if ($a->get_publish_status(@_)) {
                                                                                return $a->needs_publish(@_) ? '<img src="/media/images/P_red.gif" border=0 width="15" height="15" />' : '<img src="/media/images/P_green.gif" border=0 width="15" height="15" />';
                                                                        } }, 
                  get_args => [],
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
                              len      => 1024,
                              req      => 0,
                              type     => 'short',
                              props    => {   type => 'textarea',
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
              element_id => {
                              name     => 'element_id',
                              get_meth => sub { shift->get_element__id(@_) },
                              get_args => [],
                              set_meth => sub { shift->set_element__id(@_) },
                              set_args => [],
                              disp     => 'Asset Type ID',
                              len      => 10,
                              req      => 0,
                              type     => 'short',
                             },
              element  => {
                              name     => 'element',
                              get_meth => sub {
                                  my $a_id = shift->get_element__id(@_);
                                  my $a = Bric::Biz::AssetType->lookup({ id => $a_id });
                                  $a->get_name(); },
                              get_args => [],
                              disp     => 'Asset Type',
                              len      => 256,
                              type     => 'short',
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
             };
    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}];
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

This sets the description on the asset

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

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

=item $user__id = $asset->get_user__id()

Returns the user__id of the person to whom the asset is checked out to

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

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

=item $user__id = $asset->get_modifier()

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
    return $self->get_current_version == $self->get_published_version ? 0 : 1;
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

=item $list or @list = $self->get_desk_stamps();

This returns a reference to a list of desk stamps in scalar context
or an array in array context

B<Throws:>

NONE 

B<Side Effects:>

NONE 

B<Notes:>

NONE

=cut

sub get_desk_stamps {
    my ($self) = @_;
    my $ds = $self->_get_attr_hash({ subsys => 'deskstamps' });

    # This needs to be a numerical sort (perl defaults to a alphanumeric sort)
    my @keys = sort {$a <=> $b} keys %$ds;

    my (%dc, @desks);
    foreach (@keys) {
        push @desks, $dc{$ds->{$_}} ||=
          Bric::Biz::Workflow::Parts::Desk->lookup({id => $ds->{$_}});
    }
    return wantarray ? @desks : \@desks;
}

################################################################################

=item $self = $self->set_current_desk ( $desk_object );

This method takes a desk stamp object and adds it to the asset object

B<Throws:>

NONE 

B<Side Effects:>

NONE 

B<Notes:>

NONE

=cut

sub set_current_desk {
    my ($self, $desk) = @_;
    my $desk_id     = $desk->get_id();
    $self->_set({desk_id => $desk_id});
    return $self;
}

################################################################################

=item $ld = $self->get_current_desk ( );

This returns the desk stamp of the desk that the object is currently 
at

B<Throws:>

NONE 

B<Side Effects:>

NONE 

B<Notes:>

NONE

=cut

sub get_current_desk {
    my $self = shift;
    my ($id, $desk) = $self->_get(qw(desk_id _desk));
    return $desk if $desk;
    $desk = Bric::Biz::Workflow::Parts::Desk->lookup({ id => $id });
    $self->_set(['_desk'], [$desk]);
    return $desk;
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

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

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
    my $w_id = $self->get_workflow_id;

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

################################################################################

=item $self = $self->cancel ();

Reverts the actions of a fork with out committing any changes.   Deletes
row for the checked out asset

B<Throws:>

NONE

B<Side Effects:>

Removes the Asset (version) record from the database

B<Notes:>

NONE

=cut

################################################################################

=item  $self->set_note ( $note );

Adds a note to the Asset Takes a note object. Flags that a new note record
should be created come data base time

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub add_note {
        my $self = shift;
        my ($note) = @_;


        my $notes = $self->_get_attr_hash({ subsys => 'notes'});

        my $note_index = $self->get_version();

        $self->_set_attr({ 
                        subsys => 'notes', 
                        name => $note_index,
                        sql_type => 'short', 
                        value => $note
                });

        return $self;
}

################################################################################

=item  $self->get_notes ( );

Returns a list of Notes from the Asset

B<Throws:>

NONE 

B<Side Effects:>

NONE 

B<Notes:>

NONE

=cut

sub get_notes {
        my $self = shift;

        my $notes = $self->_get_attr_hash({ subsys => 'notes' });

        return $notes;
}

################################################################################

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

=item $self = $self->cancel_checkout()

Cancels the checkout.   Deletes the version instance record and its associated.
Files

B<Throws:>

"Asset is Not Checked Out"

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub cancel_checkout {
        my ($self) = @_;

        $self->_set( {
                user__id => undef,
                checked_out => 0,
                _cancel         => 1
                });

        return $self;
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
    die Bric::Util::Fault::Exception::GEN->new
      ({ msg => "Cannot checkin non checked out versions" })
      unless $self->_get('checked_out');

    my $version = $self->_get('version');
    $version++;
    $self->_set({ user__id => undef,
                  version   => $version,
                  current_version => $version,
                  checked_out => 0,
                  _checkin => 1
                });

    return $self;
}

################################################################################

=item $self = $self->save()

Preforms save functions for the asset objects.   This will sync the attributes
for the asset

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub save {
        my ($self) = @_;

        $self->_sync_attributes();

        return $self;
}

################################################################################

=back

=head1 PRIVATE


=head2 Private Class Methods

NONE

=head2 Private Instance Methods

=over 4

=item attrs = $self->_get_attr_hash()

Returns the attributes from the cache or the object

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_attr_hash {
    my ($self, $param) = @_;
    my $attrs;
    if ($self->_get('id')) {
        my $attr_obj = $self->_get_attribute_object();
        $attrs = $attr_obj->get_attr_hash( $param);
    } else {
        my $attr_cache = $self->_get('_attr_cache');
        foreach (keys %{ $attr_cache->{$param->{'subsys'}} } ) {
            $attrs->{$_} = $attr_cache->{$param->{'subsys'}}->{$_}->{'value'};
        }
    }
    return $attrs;
}

################################################################################

=item $self = $self->_set_attr()

Sets the attributes to the object or to a cache

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _set_attr {
        my ($self, $param) = @_;

        my $dirty = $self->_get__dirty();

        # check to see if we have an id, get attr obj if we do
        # otherwise put it into a cache 
        if ($self->_get('id') ) {
                my $attr_obj = $self->_get_attribute_object();

                # param should have been passed in an acceptable manner
                # send it straight to the attr obj
                $attr_obj->set_attr( $param );

        } else {
                # get the cache or create a new one if necessary
                my $attr_cache = $self->_get('_attr_cache') || {};

                # the value for this subsys/name combo
                $attr_cache->{$param->{'subsys'}}->{$param->{'name'}}->{'value'} =
                        $param->{'value'};

                # the sql type 
                $attr_cache->{$param->{'subsys'}}->{$param->{'name'}}->{'type'} =
                        $param->{'sql_type'};

                # store the cache so we can access it later
                $self->_set( { '_attr_cache' => $attr_cache });
        }

        # set the flag to update the attrs
        $self->_set( { '_update_attrs' => 1 });

        $self->_set__dirty($dirty);

        return $self;
}

################################################################################

=item $attr = $self->_get_attr($param)

Returns the attr from either the cache or the object

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_attr {
        my ($self, $param) = @_;

        # check for an id to see if we need to access the cache or
        # the attribute object
        my $attr;
        if ($self->_get('id') ) {
                # we have an id so get the attribute object
                my $attr_obj = $self->_get_attribute_object();

                # param should have been passed in a valid format
                # send directly to the attr object
                $attr = $attr_obj->get_attr( $param );

        } else {

                # get the cache if it exists or create if it does not
                my $attr_cache = $self->_get('_attr_cache') || {};

                # get the data to return 
                $attr =
                        $attr_cache->{$param->{'subsys'}}->{$param->{'name'}}->{'value'};
        }

        return $attr;
}

################################################################################

=item $self = $self->_sync_attributes()

Syncs the attributes if anything is needed to be done

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _sync_attributes {
        my ($self) = @_;

        return $self unless $self->_get('_update_attrs');

        my $attr_obj = $self->_get_attribute_object();
        $attr_obj->save();

        # see if we have attr in the cache to be stored...
        my $attr_cache = $self->_get('_attr_cache');
        if ($attr_cache) {
                # retrieve cache and store it on the attribute object
                foreach my $subsys (keys %$attr_cache) {
                        foreach my $name (keys %{ $attr_cache->{$subsys} }) {
                                # set the attribute
                                $attr_obj->set_attr( {
                                                subsys => $subsys,
                                                name => $name,
                                                sql_type => $attr_cache->{$subsys}->{$name}->{'type'},
                                                value => $attr_cache->{$subsys}->{$name}->{'value'}
                                        });
                        }
                }

                # clear the attribute cache
                $self->_set( { '_attr_cache' => undef });
        }
        # clear the update flag
        $self->_set( { '_update_attrs' => undef });

        # call save on the attribute object
        $attr_obj->save();

        return $self;
}

################################################################################

=back

=head2 Private Functions

NONE

=cut

1;

__END__

=head1 NOTES

define supported keys for list

are desk_stamps objects or just data

rewrite description to reflect current state

accessor for asset_version_id (what does get_id return the asset id or the
asset version group? )

=head1 AUTHOR

michael soderstrom ( miraso@pacbell.net )

=head1 SEE ALSO

L<Bric.pm>,L<Bric::Util::Group::AssetVersion>

=cut
