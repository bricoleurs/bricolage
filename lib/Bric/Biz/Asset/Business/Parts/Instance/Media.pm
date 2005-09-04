package Bric::Biz::Asset::Business::Parts::Instance::Media;
###############################################################################

=head1 NAME

Bric::Biz::Asset::Business::Parts::Instance::Media - Media Instance class

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
use Bric::Config qw(:media :thumb MASON_COMP_ROOT PREVIEW_ROOT);

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

use constant MIME_FILE_ROOT => Bric::Util::Trans::FS->cat_dir(
    MASON_COMP_ROOT->[0][1], qw(media mime)
);

use constant MIME_URI_ROOT => Bric::Util::Trans::FS->cat_uri('', qw(media mime));


use constant TABLE          => 'media_instance';
use constant MEDIA_TABLE    => 'media';

use constant COLS       => qw( name
                               description
                               input_channel__id
                               file_size
                               file_name
                               location
                               uri );
                               
use constant MEDIA_COLS => qw( element__id );

use constant FIELDS     => qw( name
                               description
                               input_channel_id
                               file_size
                               file_name
                               location
                               uri );
                               
use constant STORY_FIELDS => qw( element__id );
                               
# the mapping for building up the where clause based on params
use constant WHERE => 'i.id = mimv.media_instance__id '
                    . 'AND mimv.media_version__id = v.id '
                    . 'AND v.media__id = m.id';
  
use constant COLUMNS => join(', i.', 'i.id', COLS) .
                        join(', m.', '', MEDIA_COLS);
use constant RO_COLUMNS => '';

# param mappings for the big select statement
use constant FROM => TABLE . ' i, ' . MEDIA_TABLE . ' m, '
                   . 'media_instance__media_version mimv, '
                   . 'media_version v';

use constant PARAM_FROM_MAP => {
       data_text            => 'media_data_tile md',
       subelement_key_name  => 'media_container_tile mct',
       related_story_id     => 'media_container_tile mctrs',
       related_media_id     => 'media_container_tile mctrm',
};

use constant PARAM_WHERE_MAP => {
      id                     => 'i.id = ?',
      name                   => 'LOWER(i.name) LIKE LOWER(?)',
      subelement_key_name    => 'i.id = mct.object_instance_id AND LOWER(mct.key_name) LIKE LOWER(?)',
      related_story_id       => 'i.id = mctrs.object_instance_id AND mctrs.related_instance__id = ?',
      related_media_id       => 'i.id = mctrm.object_instance_id AND mctrm.related_media__id = ?',
      data_text              => 'LOWER(md.short_val) LIKE LOWER(?) AND md.object_instance_id = i.id',
      title                  => 'LOWER(i.name) LIKE LOWER(?)',
      description            => 'LOWER(i.description) LIKE LOWER(?)',
      uri                    => 'LOWER(i.uri) LIKE LOWER(?)',
      file_name              => 'LOWER(i.file_name) LIKE LOWER(?)',
      location               => 'LOWER(i.location) LIKE LOWER(?)',
      input_channel_id       => 'i.input_channel__id = ?',
      primary_ic             => 'v.primary_ic__id = i.input_channel__id ',
      primary_ic_id          => 'v.primary_ic__id = ? ',
};

use constant PARAM_ANYWHERE_MAP => {
    subelement_key_name    => [ 'i.id = mct.object_instance_id',
                                'LOWER(mct.key_name) LIKE LOWER(?)' ],
    related_story_id       => [ 'i.id = mctrs.object_instance_id',
                                'mctrs.related_instance__id = ?' ],
    related_media_id       => [ 'i.id = mctrm.object_instance_id',
                                'mctrm.related_media__id = ?' ],
    data_text              => [ 'md.object_instance_id = i.id',
                                'LOWER(md.short_val) LIKE LOWER(?)' ],
    input_channel_id       => [ 'i.input_channel__id = ?' ],
};

use constant PARAM_ORDER_MAP => {
    name                => 'LOWER(i.name)',
    title               => 'LOWER(i.name)',
    description         => 'LOWER(i.description)',
    id                  => 'i.id',
    input_channel_id    => 'i.input_channel__id',
    uri                 => 'LOWER(i.uri)',
    category_uri        => 'LOWER(i.uri)',
    file_name           => 'LOWER(i.file_name)',
    location            => 'LOWER(i.location)',
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
                'file_name'               => Bric::FIELD_READ,
                'size'                    => Bric::FIELD_RDWR,
                'location'                => Bric::FIELD_READ,
                'uri'                     => Bric::FIELD_READ,
                
                # Private Fields
                '_file'                   => Bric::FIELD_NONE,
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

=item $media = Bric::Biz::Asset::Business::Parts::Instance::Media->new( $initial_state )

This will create a new media instance with an optionally defined initial state

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

=item $asset = Bric::Biz::Asset::Business::Parts::Instance::Media->lookup({ id => $id })

This will return an asset that matches the ID provided.

B<Throws:>

"Missing required parameter 'id'"

=cut

################################################################################

=item (@media || $media) = Bric::Biz::Asset::Business::Parts::Instance::Media->list($params)

=cut

=item (@ids||$ids) = Bric::Biz::Asset::Business::Parts::Instance::Media->list_ids($params)

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

sub key_name { 'media_instance' }

#--------------------------------------#

=back

=head2 Public Class Methods

=over 4

=item $meths = Bric::Biz::Asset::Business::Parts::Instance::Media->my_meths

=item my @meths = Bric::Biz::Asset::BusinessParts::Instance::Media->my_meths(TRUE)

=item my @meths = Bric::Biz:::Asset::BusinessParts::Instance::Media->my_meths(0, TRUE)

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
                file_name   => { name     => 'file_name',
                                 get_meth => sub { shift->get_file_name(@_) },
                                 get_args => [],
                                 disp     => 'File Name',
                                 len      => 256,
                                 req      => 1,
                                 type     => 'short',
                                 props    => { type      => 'text',
                                               length    => 32,
                                               maxlength => 256
                                             }
                               },
               };
               
    # Copy the data for the title from name.
    $METHS->{title} = { %{ $METHS->{name} } };
    $METHS->{title}{name} = 'title';
    $METHS->{title}{disp} = 'Title';

    # Rename element.
    $METHS->{element} = { %{ $METHS->{element} } };
    $METHS->{element}{disp} = 'Media Type';

    return !$ord ? $METHS : wantarray ? @{$METHS}{@ORD} : [@{$METHS}{@ORD}];
}

################################################################################

=item ($fields || @fields) =
        Bric::Biz::Asset::Business::Parts::Instance::Media::autopopulated_fields()

Returns a list of the names of fields that are registered in the database as
being autopopulatable for a given sub class

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub autopopulated_fields {
    my $self = shift;
    my $fields = $self->_get_auto_fields;
    return wantarray ? keys %$fields : [keys %$fields];
}

################################################################################

=item my $hashref = Bric::Biz::Asset::Business::Parts::Instance::Media->thumbnail_uri()

This method returns a local URI pointing to an icon representing the media type
of the media document. If no file has been uploaded to the media document,
C<thumbnail_uri()> will return C<undef>.

This method is only enabled if the C<USE_THUMBNAILS> F<bricolage.conf>
directive is enabled. It may be overridden in subclasses to return a different
URI value (See Bric::Biz::Asset::Business::Media::Image for an example).

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub thumbnail_uri {
    return unless USE_THUMBNAILS;
    my $self = shift;
    return unless $self->get_path;

    # Just return the default icon if there is no media type (unlikely).
    my $mime = $self->get_media_type or return
      Bric::Util::Trans::FS->cat_uri(MIME_URI_ROOT, 'none.png');
    $mime = $mime->get_name;
    my ($cat, $type) = split '/', $mime, 2;

    # If there's a PNG file for this media type, return its URI.
    return Bric::Util::Trans::FS->cat_uri(MIME_URI_ROOT, "$mime.png")
      if -e Bric::Util::Trans::FS->cat_file(MIME_FILE_ROOT, $cat, "$type.png");

    # If there's a PNG file for the media type category, return its URI.
    return Bric::Util::Trans::FS->cat_uri(MIME_URI_ROOT, "$cat.png")
      if -e Bric::Util::Trans::FS->cat_file(MIME_FILE_ROOT, "$cat.png");

    # Otherwise, just return the default icon.
    return Bric::Util::Trans::FS->cat_uri(MIME_URI_ROOT, 'none.png');
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
    my $loc = $self->get_location || return;
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
    return unless defined $mt_id;

    unless ($mt_obj) {
        $mt_obj = Bric::Util::MediaType->lookup({'id' => $mt_id});
        $self->_set(['_media_type_obj'], [$mt_obj]);
    }
    return $mt_obj;
}

################################################################################

=item $media = $media->upload_file($file_handle, $file_name)

=item $media = $media->upload_file($file_handle, $file_name, $media_type)

=item $media = $media->upload_file($file_handle, $file_name, $media_type, $size)

Reads a file from the passed $file_handle and stores it in the media object
under $file_name. If $media_type is passed, it will be used to set the media
type of the file. Otherwise, C<upload_file()> will use Bric::Util::MediaType
to determine the media type. If $size is passed, its value will be used for
the size of the file; otherwise, C<upload_file()> will figure out the file
size itself.

B<Throws:> NONE.

B<Side Effects:> Closes the C<$file_handle> after reading. Updates the media
document's URI.

B<Notes:> NONE.

=cut

sub upload_file {
    my ($self, $fh, $name, $type, $size) = @_;

    my ($id, $v, $old_fn, $loc, $uri) =
      $self->_get(qw(id version file_name location uri));
    my $dir = Bric::Util::Trans::FS->cat_dir(MEDIA_FILE_ROOT, $id, $v);
    Bric::Util::Trans::FS->mk_path($dir);
    my $path = Bric::Util::Trans::FS->cat_dir($dir, $name);

    if (MEDIA_UNIQUE_FILENAME) {
        # split the uploaded filename into prefix and ext
        (my ($prefix,$ext)) = ($name =~  m/^(.+)(\.[^\.]+)$/ );
        # is this a new version of an existing ID ?
        if ($old_fn) {
            # set the prefix to the prefix of the old filename
            ($prefix) = ($old_fn =~ m/^(.+)\.[^\.]+$/i );
        } else {
            # generate a new prefix and make sure it is unique
            my $idexists = 1;
            while ($idexists) {
                # generate new random 8 character filename
                $prefix = substr(Digest::MD5::md5_hex(Digest::MD5::md5_hex(time.{}.$id.rand)), 0, 8);
                # add any required filename prefix if we need to 
                $prefix = MEDIA_FILENAME_PREFIX . $prefix if (MEDIA_FILENAME_PREFIX);
                # does this filename exist in DB regardless of extension ?
                ($idexists) = Bric::Biz::Asset::Business::Media->list_ids( {file_name => "$prefix%" } );
            }
        }
        # construct the new filename
        $name = $prefix . $ext;
    }

    open FILE, ">$path"
      or throw_gen(error => "Unable to open '$path': $!");
    my $buffer;
    while (read($fh, $buffer, 10240)) { print FILE $buffer }
    close $fh;
    close FILE;
    $self->_set(['needs_preview'] => [1]) if AUTO_PREVIEW_MEDIA;

    # Set the media type and the file size.
    if ($type = defined $type
        ? Bric::Util::MediaType->lookup({name => $type})
        : undef)
    {
        # We got a valid type.
        $self->_set(['media_type_id', '_media_type_obj'], [$type->get_id, $type]);
    } elsif (my $mid = Bric::Util::MediaType->get_id_by_ext($name)) {
        # We figured out the type by the filename extension.
        $self->_set(['media_type_id', '_media_type_obj'], [$mid, undef]);
    } else {
        # We have no idea what the type is. :-(
        $self->_set(['media_type_id', '_media_type_obj'], [0, undef]);
    }

    $self->set_size(defined $size ? $size : -s $path);

    # Get the Output Channel object.
    my $at_obj = $self->get_element_object;
    my $oc_obj = $self->get_primary_oc;

    my $new_loc = Bric::Util::Trans::FS->cat_dir('/', $id, $v, $name);

    # Set the location, name, and URI.
    if (not defined $old_fn
        or not defined $uri
        or $old_fn ne $name
        or $loc ne $new_loc) {
        $self->_set(['file_name'], [$name]);
        $uri = Bric::Util::Trans::FS->cat_uri
          ($self->_construct_uri($self->get_category_object, $oc_obj),
           $oc_obj->get_filename($self));

        $self->_set([qw(location  uri   _update_uri)] =>
                    [   $new_loc, $uri, 1]);
    }

    if (my $auto_fields = $self->_get_auto_fields) {
        # We need to autopopulate data field values. Get the top level element
        # construct a MediaFunc object.
        my $tile = $self->get_tile;
        my $path = Bric::Util::Trans::FS->cat_dir(MEDIA_FILE_ROOT, $new_loc);
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

sub delete_file {
    my ($self) = @_;
    
    $self->_set([qw(file_name location  uri _update_uri)] =>
                [   undef, undef, undef, 1]);
                
    return $self;
}

################################################################################

=item $file_name = $media->get_file_name()

Returns the name of the file for this given media object.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub get_file_name {
    my $self = shift;
    if (my $alias = $self->_get_alias) {
        return $alias->get_file_name;
    }
    return $self->_get('file_name');
}

################################################################################

=item $file_handle = $media->get_file()

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
    open $fh, $path or throw_gen(error => "Cannot open '$path': $!");
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

sub get_location {
    my $self = shift;
    if (my $alias = $self->_get_alias) {
        return $alias->get_location;
    }
    return $self->_get('location');
}

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

=item $media = $media->clone()

Clones the media object

=cut

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

