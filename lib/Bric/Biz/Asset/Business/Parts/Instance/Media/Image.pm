package Bric::Biz::Asset::Business::Parts::Instance::Media::Image;
################################################################################

=head1 NAME

Bric::Biz::Asset::Business::Parts::Instance::Media::Image - the media class that 
represents static images

=head1 VERSION

$LastChangedRevision$

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 DATE

$Data$

=head1 SYNOPSIS

 # Creation of new Image instances
 $image = Bric::Biz::Asset::Business::Parts::Instance::Media::Image->new( $init )
 $image = Bric::Biz::Asset::Business::Parts::Instance::Media::Image->lookup( { id => $id })
 ($images || @images) = Bric::Biz::Asset::Business::Parts::Instance::Media::Image->list( $param)

 # list of ids
 ($id_list || @ids) = Bric::Biz::Asset::Business::Parts::Instance::Media::Image->list_ids($param)

=head1 DESCRIPTION

The Subclass of Media that pretains to Images

=cut

#==============================================================================#
# Dependencies                  #
#===============================#

#-------------------------------#
# Standard Dependancies

use strict;

#-------------------------------#
# Programatic Dependancies

#==============================================================================#
# Inheritance                   #
#===============================#

# the parent module should have a 'use' line if you need to import from it.
# use Bric;

use base qw( Bric::Biz::Asset::Business::Parts::Instance::Media );
use Bric::Config qw(:media :thumb);
use Bric::Util::Fault qw(throw_error throw_gen);
require Imager if USE_THUMBNAILS;

#==============================================================================#
# Function Prototypes           #
#===============================#

# None

#==============================================================================#
# Constants                     #
#===============================#

# None

#==============================================================================#
# Fields                        #
#===============================#

#-------------------------------#
# Public Class Fields

# Public Fields should use 'vars'
# use vars qw();

#-------------------------------#
# Private Class Fields

# Private fields use 'my'

#-------------------------------#
# Instance Fields

# None

# This method of Bricolage will call 'use fields for you and set some permissions.

BEGIN {
	Bric::register_fields( {
		# Public Fields

		# Private Fields

	});
}

#==============================================================================#
# Interface Methods             #
#===============================#

=head1 INTERFACE

=head2 Constructors

=over 4

=cut

#-------------------------------#
# Constructors

#------------------------------------------------------------------------------#

=item $image = Bric::Biz::Asset::Business::Media::Image->new($init)

This will create a new image object.

Supported Keys:

=over 4

=item *

Put Itmes here

=back

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#sub new {
#	my ($self, $init) = @_;
#
#	$self = bless {}, $self unless ref $self;

#	$self->SUPER::new($init);

#	return $self;
#}

################################################################################

=item $media = Bric::Biz::Asset::Business::Media::Image->lookup( { id => $id })

This will return the matched looked up object

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#sub lookup {
#	my ($class, $param) = @_;

#	my $self;

#	return $self;
#}

################################################################################

=item ($imgs || @imgs) = Bric::Biz::Asset::Business::Media::Image->list($param)

Returns a list of image objects that match the params passed in

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#sub _do_list {
#	my ($class, $param) = @_;

#}

################################################################################

#----------------------------#

=back

=head2 Destructors

=over 4

=item $self->DESTROY

dummy method to not wast the time of AUTHLOAD

=cut

sub DESTROY {
	# This method should be here even if its empty so that we don't waste time
	# making Bricolage's autoload method try to find it.
}

################################################################################

#-----------------------------#

=back

=head2 Public Class Methods

=over

=item (@ids || $ids) = Bric::Biz::Asset::Business::Media::Image->list_ids($param)

Returns a list of ids that match the particular params

Supported Keys:

=over 4

=item *

Put Keys Here

=back

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#sub list_ids {
#	my ($class, $params) = @_;

#}

################################################################################

=item $class_id = Bric::Biz::Asset::Business::Media::Image->get_class_id()

Returns the class id of the Image class

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_class_id {
	return 50;
}

################################################################################

=item my $key_name = Bric::Biz::Asset::Business::Media::Image->key_name()

Returns the key name of this class.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

#sub key_name { 'image' }

################################################################################

=item my_meths()

Data Dictionary for introspection of the object

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

#-----------------------------#

=back

=head2 Public Instance Methods

=over 4

=item my $thumbnail_uri = $image->thumbnail_uri

If the image document has an associated thumbnail image, this method returns
its local URI.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub thumbnail_uri {
    return unless USE_THUMBNAILS;
    my $self = shift;
    my $loc = $self->_thumb_location or return $self->SUPER::thumbnail_uri;
    return $self->SUPER::thumbnail_uri
      unless -e $self->_thumb_file || $self->create_thumbnail;
    return Bric::Util::Trans::FS->cat_uri(
        MEDIA_URI_ROOT,
        Bric::Util::Trans::FS->dir_to_uri($loc)
    );
}

###################################################################### ##########

=item my $created_ok = $image->create_thumbnail

Creates a thumbnail image from the supplied image object. Returns 1 on
successful completion or error string if it fails.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub create_thumbnail {
    return unless USE_THUMBNAILS;
    my $self = shift;
    my $path = $self->get_path or return;

    # Get the media format. Try using the MIME type, and fall back on what Imager
    # guesses.
    my $format;
    if (my $mime = $self->get_media_type) {
        (my $mt = $mime->get_name) =~ s|.*/||;
        $format = $Imager::FORMATGUESS->(".$mt")
    } else {
        $format = $Imager::FORMATGUESS->($path);
    }

    # Just warn and retrun if we can't tell what format of file this is.
    unless ($format) {
        warn "Imager does not recognize the format file '$path'. No "
          . "thumbnail will be created.\n";
        return;
    }

    # Just warn and return if Imager doesn't support the format.
    unless ($Imager::formats{$format}) {
        warn qq{It looks like the image library to handle the "$format" }
          . 'fomat is not installed. No thumbnail will be created for file '
          . "'$path'.\n";
        return;
    }

    my $img = Imager->new;
    $img->open(file => $path, type => $format)
      or throw_gen error   => "Imager cannot open '$path'",
                   payload => $img->errstr;

    # If either dimension is greather than the thumbnail size, create a
    # smaller version by scaling largest side to THUMBNAIL_SIZE
    if ($img->getwidth > THUMBNAIL_SIZE || $img->getheight > THUMBNAIL_SIZE) {
        $img = $img->scale(xpixels => THUMBNAIL_SIZE,
                           ypixels => THUMBNAIL_SIZE,
                           type    => 'min');
    }

    # Save the image or die.
    my $thumbfile = $self->_thumb_file;
    $img->write(file => $thumbfile)
      or throw_gen error   => "Imager cannot write '$thumbfile'",
        payload => $img->errstr;
    return $self;
}

################################################################################

=item ($imgs || @imgs) = $image->upload_file

Overrides the C<upload_file()> method in the parent class and then makes a
call to the C<create_thumbnail()> method.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub upload_file {
    my $self = shift;
    $self->SUPER::upload_file(@_);
    $self->create_thumbnail if USE_THUMBNAILS;
    return $self;
}

=back

=cut

##############################################################################

=head1 PRIVATE

=head2 Private Class Methods

NONE

=head2 Private Instance Methods

=over 4

=item _thumb_location

  my $thumb_location = $self->_thumb_location;

Returns the location of a thumnail image file. This method simply modifies the
value returned by C<get_location> to generate the name of the image file. Returns
C<undef> if the image has no location.

=cut

sub _thumb_location {
    my $self = shift;
    my $loc = $self->get_location or return;
    $loc =~ s/(\..+)$/_thumb$1/g or $loc .= '_thumb';
    return $loc;
}

=item _thumb_file

  my $thumb_file = $self->_thumb_file;

Returns the absolute path to the thumnail image file for this image.

=cut

sub _thumb_file {
    my $self = shift;
    my $loc = $self->_thumb_location or return;
    return Bric::Util::Trans::FS->cat_file(MEDIA_FILE_ROOT,  $loc);
}

=back

=cut

1;
__END__

=head1 NOTES

NONE

=head1 AUTHOR

"Michael Soderstrom" <miraso@pacbell.net>

=head1 SEE ALSO

L<perl> , L<Bric>, L<Bric::Biz::Asset>, L<Bric::Biz::Asset::Business>,
L<Bric::Biz::Asset::Business::Media>

=cut
