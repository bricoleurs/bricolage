package Bric::Biz::Asset::Business::Media::Image;
################################################################################

=head1 NAME

Bric::Biz::Asset::Business::Media::Image - the media class that represents static
images

=head1 VERSION

$Revision: 1.8 $

=cut

our $VERSION = (qw$Revision: 1.8 $ )[-1];

=head1 DATE

$Data$

=head1 SYNOPSIS

 # Creation of new Image objects
 $image = Bric::Biz::Asset::Business::Media::Image->new( $init )
 $image = Bric::Biz::Asset::Business::Media::Image->lookup( { id => $id })
 ($images || @images) = Bric::Biz::Asset::Business::Media::Image->list( $param)

 # list of ids
 ($id_list || @ids) = Bric::Biz::Asset::Business::Media::Image->list_ids($param)

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

use base qw( Bric::Biz::Asset::Business::Media );
use Bric::Config qw(:media :thumb);
use Bric::Util::Fault qw(throw_error throw_gen);

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

=item my $thumbnail_info =  Bric::Biz::Asset::Business::Media::Image->thumbnail_info()

Returns either a reference to a hash containing the URI, width, and height for
a correctly produced image thumbnail. On encountering an error,
C<thumbnail_info()> returns a scalar error message.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub thumbnail_info {
    my $self = shift;
    my %objhash = ('uri'=>'', 'width'=>'', 'height'=>'');
    my $loc = $self->get_location;

    # thumbnail should be in same place as orig but with _thumb in filename
    $loc =~ s/(\..+)$/_thumb$1/g;
    my $thumbfile = Bric::Util::Trans::FS->cat_file(MEDIA_FILE_ROOT,  $loc);

    # if thumb doesn't exist then create_thumbnail and return message if fails
    unless (-e $thumbfile) {
        my $check = $self->create_thumbnail;
        return "Can't make thumbnail" unless $check == 1;
    }

    # get the width and height and return them along with the uri
    my $info = Image::Info::image_info($thumbfile);
    ($objhash{'width'}, $objhash{'height'}) = Image::Info::dim($info);
    $objhash{'uri'} = Bric::Util::Trans::FS->cat_uri(MEDIA_URI_ROOT,  $loc);
    return \%objhash;
}

###################################################################### ##########

=item my $created_ok =  Bric::Biz::Asset::Business::Media::Image->create_thumbnail()

Creates a thumbnail image from the supplied image object. Returns 1 on
successful completion or error string if it fails.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

sub create_thumbnail {
    my $self = shift;
    my $format;
    my $img = Imager->new;
    # this will fail if image type not supported
    eval { $img->open(file => $self->get_path) };
    return $@ if $@;
    my $thumbfile = $self->get_location;

    # save thumb to same place as image but append _thumb to filename
    $thumbfile =~ s/(\..+)$/_thumb$1/g;
    $thumbfile = Bric::Util::Trans::FS->cat_file(MEDIA_FILE_ROOT,  $thumbfile);

    # Create smaller version by scaling largest side to THUMBNAIL_SIZE
    my $thumb = $img->scale(xpixels => THUMBNAIL_SIZE,
                            ypixels => THUMBNAIL_SIZE,
                            type    => 'min');

    # save the image or return $! if fail
    $thumb->write(file => $thumbfile) or return $!;
    return 1;
}

################################################################################

=item ($imgs || @imgs) =  Bric::Biz::Asset::Business::Media::Image->upload_file()

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
    if (USE_THUMBNAILS && $self->get_path) { # ie file saved okay
        my $check = $self->create_thumbnail;
        # If the required library isn't loaded then warn gracefully
        if ($check =~ /locate auto\/Imager/) {
            throw_error
              msg      => "Could not create thumbnail image. It looks like "
                        . "you have not installed the image libraries to "
                        . qq{handle the "$check" image format.},
              maketext => ["Could not create thumbnail image. It looks like "
                           . "you have not installed the image libraries to "
                           . 'handle the "[_1]" image format.', $check ];
        } elsif ($check != 1) {
            # otherwise throw a full on exception
            throw_gen $check;
        }
    }
    return $self;
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

NONE

=head1 PRIVATE

NONE

=head2 Private Class Methods

NONE

=head2 Private Instance Methods

NONE

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
