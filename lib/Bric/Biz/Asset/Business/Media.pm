package Bric::Biz::Asset::Business::Media;
###############################################################################

=head1 NAME

Bric::Biz::Asset::Business::Media - The parent class of all media objects

=head1 VERSION

$Revision: 1.46 $

=cut

our $VERSION = (qw$Revision: 1.46 $ )[-1];

=head1 DATE

$Date: 2003-03-19 02:06:19 $

=head1 SYNOPSIS

  use Bric::Biz::Asset::Business::Media;

=head1 DESCRIPTION

TBD.

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
use Bric::Util::Attribute::Media;
use Bric::Util::Trans::FS;
use Bric::Util::Grp::Media;
use Bric::Util::Time qw(:all);
use Bric::App::MediaFunc;
use File::Temp qw( tempfile );
use Bric::Config qw(:media);
use Bric::Util::Fault::Exception::GEN;
use Bric::Util::Fault::Exception::DA;

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

use constant TABLE  => 'media';

use constant VERSION_TABLE => 'media_instance';

use constant ID_COL => 'mt.id';

use constant COLS           => qw( element__id
                                   priority
                                   source__id
                                   current_version
                                   published_version
                                   usr__id
                                   publish_date
                                   expire_date
                                   cover_date
                                   workflow__id
                                   desk__id
                                   publish_status
                                   active
                                   site__id
                                   alias_id);

use constant VERSION_COLS   => qw( name
                                   description
                                   media__id
                                   usr__id
                                   version
                                   media_type__id
                                   primary_oc__id
                                   category__id
                                   file_size
                                   file_name
                                   location
                                   uri
                                   checked_out);

use constant FIELDS         => qw( element__id
                                   priority
                                   source__id
                                   current_version
                                   published_version
                                   user__id
                                   publish_date
                                   expire_date
                                   cover_date
                                   workflow_id
                                   desk_id
                                   publish_status
                                   _active
                                   site_id
                                   alias_id);

use constant VERSION_FIELDS => qw( name
                                   description
                                   id
                                   modifier
                                   version
                                   media_type_id
                                   primary_oc_id
                                   category__id
                                   size
                                   file_name
                                   location
                                   uri
                                   checked_out);

use constant GROUP_PACKAGE => 'Bric::Util::Grp::Media';
use constant INSTANCE_GROUP_ID => 32;

# let Asset know not to throw an exception
use constant CAN_DO_LIST_IDS => 1;
use constant CAN_DO_LIST => 1;
use constant CAN_DO_LOOKUP => 1;
use constant HAS_CLASS_ID => 1;

# relations to loop through in the big query
use constant RELATIONS => [qw( media category desk workflow)];

use constant RELATION_TABLES =>
    {
        media      => 'media_member mm',
        category   => 'category_member cm',
        desk       => 'desk_member dm',
        workflow   => 'workflow_member wm',
    };

use constant RELATION_JOINS =>
    {
        media      => 'mm.object_id = mt.id AND m.id = mm.member__id',
        category   => 'cm.object_id = i.category__id AND m.id = cm.member__id',
        desk       => 'dm.object_id = mt.desk__id AND m.id = dm.member__id',
        workflow   => 'wm.object_id = mt.workflow__id AND m.id = wm.member__id',
    };

# the mapping for building up the where clause based on params
use constant WHERE => 'mt.id = i.media__id';

use constant COLUMNS => join(', mt.', 'mt.id', COLS) . ', ' 
            . join(', i.', 'i.id AS version_id', VERSION_COLS) . ', m.grp__id';

use constant OBJECT_SELECT_COLUMN_NUMBER => scalar COLS + 1;

# param mappings for the big select statement
use constant FROM => VERSION_TABLE . ' i, member m';

use constant PARAM_FROM_MAP =>
    {
       keyword            => 'media_keyword mk, keyword k',
       simple             => 'media mt LEFT OUTER JOIN media_keyword mk LEFT OUTER JOIN keyword k ON (mk.keyword_id = k.id) ON (mt.id = mk.media_id)',
       _not_simple        => TABLE . ' mt',
       grp_id             => 'member m2, media_member mm2',
       category_uri       => 'category c'
    };

use constant PARAM_WHERE_MAP =>
    {
      id                    => 'mt.id = ?',
      active                => 'mt.active = ?',
      inactive              => 'mt.active = ?',
      alias_id              => 'mt.alias_id = ?',
      site_id               => 'mt.site__id = ?',
      no_site_id            => 'mt.site__id <> ?',
      workflow__id          => 'mt.workflow__id = ?',
      _null_workflow__id    => 'mt.workflow__id IS NULL',
      element__id           => 'mt.element__id = ?',
      source__id            => 'mt.source__id = ?',
      priority              => 'mt.priority = ?',
      publish_status        => 'mt.publish_status = ?',
      publish_date_start    => 'mt.publish_date >= ?',
      publish_date_end      => 'mt.publish_date <= ?',
      cover_date_start      => 'mt.cover_date >= ?',
      cover_date_end        => 'mt.cover_date <= ?',
      expire_date_start     => 'mt.expire_date >= ?',
      expire_date_end       => 'mt.expire_date <= ?',
      desk_id               => 'mt.desk_id = ?',
      name                  => 'LOWER(i.name) LIKE LOWER(?)',
      title                 => 'LOWER(i.name) LIKE LOWER(?)',
      description           => 'LOWER(i.description) LIKE LOWER(?)',
      version               => 'i.version = ?',
      user__id              => 'i.usr__id = ?',
      uri                   => 'LOWER(i.uri) LIKE LOWER(?)',
      file_name             => 'LOWER(i.file_name LIKE LOWER(?)',
      location              => 'LOWER(i.location) LIKE LOWER(?)',
      _checked_out          => 'i.checked_out = ?',
      primary_oc_id         => 'i.primary_oc__id = ?',
      category__id          => 'i.category__id = ?',
      category_id           => 'i.category__id = ?',
      category_uri          => 'i.category__id = c.id AND '
                             . 'LOWER(c.uri) LIKE LOWER(?)',
      keyword               => 'mk.media_id = mt.id AND '
                             . 'k.id = mk.keyword_id AND '
                             . 'LOWER(k.name) LIKE LOWER(?)',
      _no_returned_versions => 'mt.current_version = i.version',
      grp_id                => 'mt.current_version = i.version AND '
                             . 'm2.grp__id = ? AND '
                             . 'mm2.member__id = m2.id AND '
                             . 'mt.id = mm2.object_id',
      simple                => '( LOWER(k.name) LIKE LOWER(?) OR '
                             . 'LOWER(i.name) LIKE LOWER(?) OR '
                             . 'LOWER(i.description) LIKE LOWER(?) )',
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
      file_name           => 'file_name',
      location            => 'location',
      category_id         => 'category__id',
      category__id        => 'category__id',
      title               => 'name',
      description         => 'description',
      version             => 'version',
      version_id          => 'version_id',
      user__id            => 'usr__id',
      _checked_out        => 'checked_out',
      primary_oc_id       => 'primary_oc__id',
      category__id        => 'category__id',
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

# Public fields should use 'vars'
#use vars qw();

#--------------------------------------#
# Private Class Fields
my ($meths, @ord);
my $da = 'Bric::Util::Fault::Exception::DA';
my $gen = 'Bric::Util::Fault::Exception::GEN';

#--------------------------------------#
# Instance Fields

BEGIN {
    Bric::register_fields(
                        {
                         # Public Fields
                         location        => Bric::FIELD_READ,
                         file_name       => Bric::FIELD_READ,
                         uri             => Bric::FIELD_READ,
                         media_type_id   => Bric::FIELD_RDWR,
                         category__id    => Bric::FIELD_RDWR,
                         size            => Bric::FIELD_RDWR,

                         # Private Fields
                         _category_obj   => Bric::FIELD_NONE,
                         _file           => Bric::FIELD_NONE,
                         _media_type_obj => Bric::FIELD_NONE,
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

=item $media = Bric::Biz::Asset::Business::Media->new( $initial_state )

This will create a new media object with an optionaly defined intiial state

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

element__id - Required unless asset type object passed

=item *

element - the object required unless id is passed

=item *

source__id - required

=item *

cover_date - will set expire date in conjunction with the source

=item *

media_type_id

=item *

category__id

=back

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub new {
    my ($self, $init) = @_;
    # default to active unless passed otherwise
    $init->{_active} = (exists $init->{active}) ? $init->{active} : 1;
    delete $init->{active};
    $init->{priority} ||= 3;
    $init->{name} = delete $init->{title} if exists $init->{title};
    $self->SUPER::new($init);
}

################################################################################

=item $media = Bric::Biz::Asset::Business::Media->lookup->( { id => $id })

This will return a media asset that matches the criteria defined

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Inherited from Bric::Biz::Asset.

=cut

################################################################################

=item (@media || $media) =  Bric::Biz::Asset::Business::Media->list($param);

returns a list or list ref of media objects that match the criteria defined

Supported Keys:

=over 4

=item *

name - the same as the title field

=item *

title

=item *

description

=item *

uri

=item *

file_name - the name of the file uploaded into this object

=item *

source__id

=item *

id - the media id

=item *

version

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

workflow__id

=item *

element__id

=item *

primary_oc_id

=item *

priority

=item *

publish_status

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

simple - a single OR search that hits name, description and uri.

=item *

category__id - the category id of the media object

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

B<Notes:> Inherited from Bric::Biz::Asset.

=cut

################################################################################

#--------------------------------------#

=back

=head2 Destructors

=over 4

=item $self->DESTROY

dummy method to not waste the time of AUTOLOAD

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

=item (@ids||$id_list) = Bric::Biz::Asset::Business::Media->list_ids( $criteria );

Returns a list or list ref of media object IDs that match the criteria defined.
The criteria are the same as those for the list() method.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> Inherited from Bric::Biz::Asset.

=cut

################################################################################

=item ($fields || @fields) = 
        Bric::Biz::Asset::Business::Media::autopopulated_fields()

Returns a list of the names of fields that are registered in the database as
being autopopulatable for a given sub class

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub autopopulated_fields {
    my $self = shift;
    my $fields = $self->_get_auto_fields();

    my @auto;
    foreach (keys %$fields ) {
        push @auto, $_;
    }
    return wantarray ? @auto : \@auto;
}

################################################################################

=item my $key_name = Bric::Biz::Asset::Business::Media->key_name()

Returns the key name of this class.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub key_name { 'media' }

################################################################################

=item $meths = Bric::Biz::Asset::Business::Media->my_meths

=item (@meths || $meths_aref) = Bric::Biz::Asset::Business::Media->my_meths(TRUE)

=item my (@meths || $meths_aref) = Bric::Biz:::Asset::Business::Media->my_meths(0, TRUE)

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

    push @ord, qw(file_name category category_name), pop @ord;
    $meths->{file_name} = {
                           get_meth => sub { shift->get_file_name(@_) },
                           get_args => [],
                           name     => 'file_name',
                           disp     => 'File Name',
                           len      => 256,
                           req      => 1,
                           type     => 'short',
                           props    => { type      => 'text',
                                         length    => 32,
                                         maxlength => 256
                                       }
                          };
    $meths->{category} = {
                          get_meth => sub { shift->get_category_object(@_) },
                          get_args => [],
                          set_meth => sub { shift->set_category_object(@_) },
                          set_args => [],
                          name     => 'category',
                          disp     => 'Category',
                          len      => 64,
                          req      => 1,
                          type     => 'short',
                         };

    $meths->{category_name} = {
                          get_meth => sub { shift->get_category_object(@_)->get_name },
                          get_args => [],
                          name     => 'category_name',
                          disp     => 'Category',
                          len      => 64,
                          req      => 1,
                          type     => 'short',
                         };

        # Copy the data for the title from name.
        $meths->{title} = { %{ $meths->{name} } };
        $meths->{title}{disp} = 'Title';

    # Rename element.
    $meths->{element} = { %{ $meths->{element} } };
    $meths->{element}{disp} = 'Media Type';
    return !$ord ? $meths : wantarray ? @{$meths}{@ord} : [@{$meths}{@ord}];
}

################################################################################

=item $class_id = Bric::Biz::Asset::Business::Media->get_class_id()

Returns the class id of the Media class

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_class_id { 46 }

################################################################################

#--------------------------------------#

=back

=head2 Public Instance Methods

=over 4

=item $media = $media->set_category__id($id)

Associates this media asset with the given category

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_category__id {
    my ($self, $cat_id) = @_;

    my $cat = Bric::Biz::Category->lookup( { id => $cat_id });
    my $oc = $self->get_primary_oc;

    my $uri = Bric::Util::Trans::FS->cat_uri
      ( $self->_construct_uri($cat, $oc), $oc->get_filename($self));

    $self->_set({ _category_obj => $cat,
                  category__id  => $cat_id,
                  uri           => $uri
    });

    return $self;
}
sub get_primary_uri { shift->get_uri }

################################################################################

=item $category_id = $media->get_category__id()

Returns the category id that has been associated with this media object

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

=item $self = $media->set_cover_date($cover_date)

Sets the cover date and updates the URI.

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

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub set_cover_date {
    my $self = shift;
    $self->SUPER::set_cover_date(@_);

    my ($cat, $cat_id, $fn)
      = $self->_get(qw(_category_obj category__id file_name));
    return $self unless defined $fn;

    $cat ||= Bric::Biz::Category->lookup({ id => $cat_id });

    my $oc = $self->get_primary_oc;
    return $self unless $cat and $oc;

    my $uri = Bric::Util::Trans::FS->cat_uri($self->_construct_uri($cat, $oc),
                                             $fn);

    $self->_set({ _category_obj => $cat,
                  uri           => $uri });
}

################################################################################

=item $category = $media->get_category_object()

=item $category = $media->get_category()

Returns the object of the category that this is a member of

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_category_object {
    my $self = shift;
    my $cat = $self->_get( '_category_obj' );
    return $cat if $cat;
    $cat = Bric::Biz::Category->lookup( { id => $self->_get('category__id') });
    $self->_set({ '_category_obj' => $cat });
    return $cat;
}

*get_category = *get_category_object;

##############################################################################

=item my $uri = $media->get_uri

=item my $uri = $media->get_uri($oc)

Returns the URI for the media object. If the C<$oc> output channel parameter
is passed in, then the URI will be returned in the output channel's preferred
format.

B<Throws:>

=over 4

=item *

Output channel not associated with media.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_uri {
    my ($self, $oc) = @_;
    # Just return the URI unless we need to format it according to an output
    # channel's requirements.
    return $self->_get('uri') unless $oc;

    # Make sure we have a valid output channel.
    $oc = Bric::Biz::OutputChannel->lookup({ id =>$oc })
      unless ref $oc;
    die $da->new({ msg => "Output channel '" . $oc->get_name . "' not " .
                   "associated with media '" . $self->get_name . "'" })
      unless $self->get_output_channels($oc->get_id);

    return Bric::Util::Trans::FS->cat_uri
      ($self->_construct_uri($self->get_category_object, $oc),
       $oc->get_filename($self));
}

##############################################################################

=item $uri = $media->get_local_uri()

Returns the uri of the media object for the Bricolage application server.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_local_uri {
    my $self = shift;
    my $loc = $self->get_location || return;
    return Bric::Util::Trans::FS->cat_uri(MEDIA_URI_ROOT,
                                        Bric::Util::Trans::FS->dir_to_uri($loc) );
}

=item $uri = $media->get_path()

Returns the path of the media object on the Bricolage file system.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_path {
    my $self = shift;
    my $loc = $self->_get('location') || return;
    return Bric::Util::Trans::FS->cat_dir(MEDIA_FILE_ROOT, $loc);
}

#------------------------------------------------------------------------------#

=item $mt_obj = $media->get_media_type()

Returns the media type object associated with this object.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_media_type {
    my $self = shift;
    my ($mt_obj, $mt_id) = $self->_get('_media_type_obj', 'media_type_id');
    return unless $mt_id;

    unless ($mt_obj) {
        $mt_obj = Bric::Util::MediaType->lookup({'id' => $mt_id});
        $self->_set(['_media_type_obj'], [$mt_obj]);
    }
    return $mt_obj;
}

################################################################################

=item $media = $media->upload_file($file_handle, $file_name)

Reads a file from the passed $file_handle and stores it in the media
object under $file_name.

B<Throws:> NONE.

B<Side Effects:> Closes the $file_handle after reading.

B<Notes:> NONE.

=cut

sub upload_file {
    my ($self, $fh, $name) = @_;
    my ($id, $v) = $self->_get(qw(id version));
    my $dir = Bric::Util::Trans::FS->cat_dir(MEDIA_FILE_ROOT, $id, $v);
    Bric::Util::Trans::FS->mk_path($dir);
    my $path = Bric::Util::Trans::FS->cat_dir($dir, $name);

    open FILE, ">$path"
      or die $gen->new({ msg => "Unable to open '$path': $!" });
    my $buffer;
    while (read($fh, $buffer, 10240)) { print FILE $buffer }
    close $fh;
    close FILE;

    # Get the Output Channel object.
    my $at_obj = $self->_get_element_object;
    my $oc_obj = $self->get_primary_oc;

    # Set the location, name, and URI.
    $self->_set(['file_name'], [$name]);
    my $uri = Bric::Util::Trans::FS->cat_uri
      ($self->_construct_uri($self->get_category_object, $oc_obj),
       $oc_obj->get_filename($self));

    my $loc = Bric::Util::Trans::FS->cat_dir('/', $id, $v, $name);
    $self->_set([qw(location uri)], [$loc, $uri]);

    if (my $auto_fields = $self->_get_auto_fields) {
        # We need to autopopulate data field values. Get the top level element
        # construct a MediaFunc object.
        my $tile = $self->get_tile;
        my $path = Bric::Util::Trans::FS->cat_dir(MEDIA_FILE_ROOT, $loc);
        my $media_func = Bric::App::MediaFunc->new({ file_path => $path });

        # Iterate through all the elements.
        foreach my $dt ($tile->get_tiles) {
            # Skip container elements.
            next if $dt->is_container;
            # See if this is an auto populated field.
            my $name = $dt->get_name;
            if ($auto_fields->{$name} ) {
                # Check the tile to see if we can override it.
                next if $dt->is_locked;
                # Get and set the value
                my $method = $auto_fields->{$name};
                my $val = $media_func->$method();
                $dt->set_data(defined $val ? $val : '');
                $dt->save;
            }
        }
    }
    return $self;
}

################################################################################

=item $file_handle = $madia->get_file()

Returns the file handle for this given media object

B<Throws:>

=over

=item *

Error getting File.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_file {
    my $self = shift;
    my $path = $self->get_path || return;
    my $fh;
    open $fh, $path or die $gen->new({ msg => "Cannot open '$path': $!" });
    return $fh;
}

################################################################################

=item $location = $media->get_location()

The will return the location of the file on the file system, relative to
MEDIA_FILE_ROOT.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

################################################################################

=item $size = $media->get_size()

This is the size of the media file in bytes

B<Throws:>

=over 4

=item *

Unable to retrieve category__id of this media.

=back

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

################################################################################

=item $media_name = $media->check_uri

=item $media_name = $media->check_uri($uid)

Returns name of media with conflicting URI, if any.

=cut

sub check_uri {
    my ($self, $uid) = @_;
    my $id = $self->_get('id') || 0;

    # Get the category.
    my $media_cat = defined $self->get_category__id or die $gen->new
      ({ msg => 'Unable to retrieve category__id of this media' });

    # Get the current media's output channels.
    my @ocs = $self->get_output_channels;
    die $gen->new({ msg => 'Cannot retrieve any output channels associated ' .
                           "with this media asset's media type element" })
      if !$ocs[0];

    # Get all media in the same category.
    my $params = { category__id => $media_cat,
                   active      => 1,
                   site_id     => $self->get_site_id,
                 };

    my $medias = $self->list($params);
    if (defined $uid) {
        $params->{user__id} = $uid;
        push @$medias, $self->list($params);
    }

    # For each media asset that shares this category...
    foreach my $med (@$medias) {
        # Don't want to compare current media with itself.
        next if ($med->get_id == $id);

        # For each output channel, throw an error for conflicting URI.
        foreach my $med_oc ($med->get_output_channels) {
            foreach my $oc (@ocs) {
                # HACK: Must get rid of the message and throw an
                # exception, instead.
                return $med->get_name if
                  $med->get_uri($med_oc) eq $self->get_uri($oc);
            }
        }
    }
    return;
}

################################################################################

=item $media = $story->revert();

Reverts the current version to a prior version

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub revert {
    my ($self, $version) = @_;
    die $gen->new({ msg => "May not revert a non checked out version" })
      unless $self->_get('checked_out');

    my @prior_versions = __PACKAGE__->list( {
      id              => $self->_get_id(),
      return_versions => 1
    });

    my $revert_obj;
    foreach (@prior_versions) {
        if ($_->get_version == $version) {
            $revert_obj = $_;
        }
    }

    die $gen->new({ msg => "The requested version does not exist" })
      unless $revert_obj;

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

    # clone information from the tables
    $self->_set([qw(category__id media_type_id size file_name location uri
                    _contributors _update_contributors _queried_contrib)],
                [$revert_obj->_get(qw(category__id media_type_id size file_name
                                      location uri), $contrib, 1, 1)]);

    # clone the tiles
    # get rid of current tiles
    my $tile = $self->get_tile;
    $tile->do_delete;
    my $new_tile = $revert_obj->get_tile;
    $new_tile->prepare_clone;
    $self->_set({ _delete_tile => $tile,
                  _tile        => $new_tile});
    return $self;
}

################################################################################

=item $media = $media->clone()

Clones the media object

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub clone {
    my $self = shift;
    my $tile = $self->get_tile();
    $tile->prepare_clone();

    my $contribs = $self->_get_contributors();
    # clone contributors
    foreach (keys %$contribs ) {
        $contribs->{$_}->{'action'} = 'insert';
    }

    $self->_set( { version_id           => undef,
                   id                   => undef,
                   publish_date         => undef,
                   publish_status       => 0,
                   _update_contributors => 1
    });
    return $self;
}


################################################################################

=item $self = $self->save()

Saves the object to the database doing either an insert or
an update

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub save {
    my $self = shift;
    if ($self->_get('id')) {
        # we have the main id make sure there's a instance id
        $self->_update_media();

        if ($self->_get('version_id')) {
            if ($self->_get('_cancel')) {
                $self->_delete_instance();
                if ($self->_get('version') == 0) {
                    $self->_delete_media();
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
            # insert both
            if ($self->_get('_cancel')) {
                return $self;
            } else {
                $self->_insert_media();
                $self->_insert_instance();
            }
        }
    $self->SUPER::save();
    return $self;
}

################################################################################

#--------------------------------------#

=item $contribs = $self->_get_contributors()

Returns the contributors from a cache or looks em up

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _get_contributors {
    my $self = shift;

    my ($contrib, $queried) = $self->_get('_contributors', '_queried_contrib');

    unless ($contrib) {
        my $dirty = $self->_get__dirty();
        my $sql = 'SELECT member__id, place, role FROM media__contributor ' .
          'WHERE media_instance__id=? ';

        my $sth = prepare_ca($sql, undef, DEBUG);
        execute($sth, $self->_get('version_id'));
        while (my $row = fetch($sth)) {
            $contrib->{$row->[0]}->{'role'} = $row->[2];
            $contrib->{$row->[0]}->{'place'} = $row->[1];
        }

        $self->_set( { _queried_contrib => 1,
                       _contributors     => $contrib
        });
        $self->_set__dirty($dirty);
    }
    return $contrib;
}

################################################################################

=item $self = $self->_insert_contributor( $id, $role)

Inserts a row into the mapping table for contributors.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _insert_contributor {
    my ($self, $id, $role, $place) = @_;

    my $sql = 'INSERT INTO media__contributor ' .
      ' (id, media_instance__id, member__id, place, role) ' .
        " VALUES (${\next_key('media__contributor')},?,?,?,?) ";

    my $sth = prepare_c($sql, undef, DEBUG);
    execute($sth, $self->_get('version_id'), $id, $place, $role);
    return $self;
}

################################################################################

=item $self = $self->_update_contributor($id, $role)

Updates the contributor mapping table

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _update_contributor {
    my ($self, $id, $role, $place) = @_;
    my $sql = 'UPDATE media__contributor ' .
      ' SET role=?, place=? ' .
        ' WHERE media_instance__id=? ' .
          ' AND member__id=? ';

    my $sth = prepare_c($sql, undef, DEBUG);
    execute($sth, $role, $place, $self->_get('version_id'), $id);
    return $self;
}

################################################################################

=item $self = $self->_delete_contributors($id)

Deletes the rows from these mapping tables

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _delete_contributor {
    my ($self, $id) = @_;

    my $sql = 'DELETE FROM media__contributor ' .
      ' WHERE media_instance__id=? ' .
        ' AND member__id=? ';

    my $sth = prepare_c($sql, undef, DEBUG);
    execute($sth, $self->_get('version_id'), $id);
    return $self;
}

################################################################################

=item ($fields) = $self->_get_auto_fields($biz_pkg)

returns a hash ref of the fields that are to be autopopulated from this 
type of media object.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _get_auto_fields {
    my ($self) = @_;

    my $auto_fields;
    if (ref $self) {
        $auto_fields = $self->_get('_auto_fields');
        return $auto_fields if $auto_fields;
    }

    my $sth = prepare_c(qq{
        SELECT name, function_name
        FROM   media_fields
        WHERE  biz_pkg = ?
               AND active = ?
        ORDER BY id
    });

    execute($sth, ($self->get_class_id, 1));
    while (my $row = fetch($sth)) {
        $auto_fields->{$row->[0]} = $row->[1];
    }

    $self->_set( { '_auto_fields' => $auto_fields }) if ref $self;
    return $auto_fields;
}

################################################################################

=item $attribute_object = $self->_get_attribute_object()

Returns the attribute object from a cache or creates a new record

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _get_attribute_object {
    my $self = shift;
    my ($attr_obj, $id) = $self->_get('_attribute_object', 'id');
    return $attr_obj if $attr_obj;

    # Let's Create a new one if one does not exist
    $attr_obj = Bric::Util::Attribute::Media->new({ id => $id });
    $self->_set( {'_attribute_object' => $attr_obj} );
    return $attr_obj;
}

################################################################################

=item $self = $self->_insert_media()

Inserts a media record into the database

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _insert_media {
    my $self = shift;

    my $sql = 'INSERT INTO ' . TABLE . ' (id, ' . join(', ', COLS) . ') '.
      "VALUES (${\next_key(TABLE)}, ". join(', ',('?') x COLS).')';

    my $sth = prepare_c($sql, undef, DEBUG);
    execute($sth, $self->_get(FIELDS));
    $self->_set( { id => last_key(TABLE) });

    # And finally, register this person in the "All Media" group.
    $self->register_instance(INSTANCE_GROUP_ID, GROUP_PACKAGE);
    return $self;
}

################################################################################

=item $self = $self->_update_media()

Preforms the SQL that updates the media table

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _update_media {
    my $self = shift;

    my $sql = 'UPDATE ' . TABLE . ' SET '. join(', ', map {"$_=?"} COLS) .
      ' WHERE id=? ';

    my $sth = prepare_c($sql, undef, DEBUG);
    execute($sth, $self->_get(FIELDS), $self->_get('id'));
    return $self;
}

################################################################################

=item $self = $self->_insert_instance()

Preforms the sql that inserts a record into the media instance table

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _insert_instance {
    my $self = shift;

    my $sql = 'INSERT INTO '. VERSION_TABLE .
      ' (id, '.join(', ', VERSION_COLS) . ')' .
        " VALUES (${\next_key(VERSION_TABLE)}, ".
          join(', ', ('?') x VERSION_COLS) . ')';

    my $sth = prepare_c($sql, undef, DEBUG);
    execute($sth, $self->_get(VERSION_FIELDS));
    $self->_set( { version_id => last_key(VERSION_TABLE) });
    return $self;
}

################################################################################

=item $self = $self->_update_instance()

Preforms the sql that updates the media_instance table

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _update_instance {
    my $self = shift;

    my $sql = 'UPDATE ' . VERSION_TABLE .
      ' SET ' . join(', ', map {"$_=?" } VERSION_COLS) .
        ' WHERE id=? ';

    my $sth = prepare_c($sql, undef, DEBUG);
    execute($sth, $self->_get(VERSION_FIELDS), $self->_get('version_id'));
    return $self;
}

################################################################################

=item $self = $self->_delete_media()

Removes the media row from the database

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _delete_media {
    my $self = shift;

    my $sql = 'DELETE FROM ' . TABLE .
      ' WHERE id=? ';

    my $sth = prepare_c($sql, undef, DEBUG);
    execute($sth, $self->_get('id'));
    return $self;
}

################################################################################

=item $self = $self->_delete_instance()

Removes the instance row from the database

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _delete_instance {
    my $self = shift;

    my $sql = 'DELETE FROM ' . VERSION_TABLE .
      ' WHERE id=? ';

    my $sth = prepare_c($sql, undef, DEBUG);
    execute($sth, $self->_get('version_id'));
    return $self;
}

################################################################################

=item $self = $self->_select_media($where, @bind);

Populates the object from a database row

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _select_media {
    my ($self, $where, @bind) = @_;
    my @d;

    my $sql = 'SELECT id,'. join(',',COLS) . " FROM ". TABLE;

    # add the where Clause
    $sql .= " WHERE $where";

    my $sth = prepare_ca($sql, undef, DEBUG);
    execute($sth, @bind);
    bind_columns($sth, \@d[0 .. (scalar COLS)]);
    fetch($sth);

    # set the values retrieved
    $self->_set( [ 'id', FIELDS], [@d]);

    my $v_grp = Bric::Util::Grp::AssetVersion->lookup(
      { id => $self->_get('version_grp__id') } );
    $self->_set( { '_version_grp' => $v_grp });
    return $self;
}

################################################################################

=item $self = $self->_do_update()

Updates the row in the data base

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _do_update {
    my $self = shift;

    my $sql = 'UPDATE ' . TABLE . ' '.
      'SET ' . join(', ', map { "$_=?" } COLS) .
                                ' WHERE id=? ';

    my $update = prepare_c($sql, undef, DEBUG);
    execute($update, $self->_get( FIELDS ), $self->_get('id') );
    return $self;
}

################################################################################

=item $attr_object = $self->_get_attr_obj()

returns the attribute object for this story

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub _get_attr_obj {
    my $self = shift;
    my $attr_obj = $self->_get('_attr_obj');
    return $attr_obj if ($attr_obj);

    $attr_obj = Bric::Util::Attribute::Media->new(
      { object_id => $self->_get('id')});
    $self->_set( { '_attr_obj' => $attr_obj });
    return $attr_obj;
}

################################################################################

1;
__END__

=back

=head1 NOTES

Some additional fields may be needed here such as a field for what kind of
object this represents etc.

=head1 AUTHOR

"Michael Soderstrom" E<lt>miraso@pacbell.netE<gt>

=head1 SEE ALSO

L<perl>, L<Bric>, L<Bric::Biz::Asset>, L<Bric::Biz::Asset::Business>

=cut
