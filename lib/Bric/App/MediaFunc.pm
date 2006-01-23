package Bric::App::MediaFunc;

=head1 NAME

Bric::App::MediaFunc - Location for functions that query uploaded media files.

=head1 VERSION

$LastChangedRevision$

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 DATE

$LastChangedDate$

=head1 SYNOPSIS

TBD.

=head1 DESCRIPTION

TBD.

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Image::Info ();
use Bric::Util::Fault qw(throw_dp);

################################################################################
# Inheritance
################################################################################
use base qw(Bric);

################################################################################
# Function and Closure Prototypes
################################################################################

################################################################################
# Constants
################################################################################
use constant DEBUG => 0;

################################################################################
# Fields
################################################################################
# Public Class Fields

################################################################################
# Private Class Fields

################################################################################

################################################################################
# Instance Fields

BEGIN {
    Bric::register_fields(
			  {
			   # Public Fields

			   # Private Fields
			   _path	=> Bric::FIELD_NONE,
			   _file_handle	=> Bric::FIELD_NONE,
			   _image_info	=> Bric::FIELD_NONE
			  });
}

################################################################################
# Class Methods
################################################################################

=head1 INTERFACE

=head2 Constructors

=over 4

=item $mediafunc = Bric::App::MediaFunc->new($init);

Creates a new object to run the given methods against

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub new {
    my ($self, $init) = @_;
    $self = bless {}, $self unless ref $self;
    $init->{'_path'} = delete $init->{'file_path'};
    $self->SUPER::new($init);
    return $self;
}

=back

=head2 Destructors

=over 4

=item $p->DESTROY

Dummy method to prevent wasting time trying to AUTOLOAD DESTROY.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=back

=cut

sub DESTROY {}

################################################################################

=head2 Public Class Methods

NONE

=head2 Public Functions

=over 4

=item $height = $media_func->get_height()

Returns the height of the image

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Throws:>

NONE

=cut

sub get_height { $_[0]->_get_image_info->{height} }

################################################################################

=item $width = $media->get_width()

Returns the width of the image

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_width { $_[0]->_get_image_info->{width} }

################################################################################

=item $color_type = $media->get_color_type()

Returns the color type of the image

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_color_type { $_[0]->_get_image_info->{color_type} }

################################################################################

=item $resolution = $media->get_resolution()

Returns the resolution

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_resolution { $_[0]->_get_image_info->{resolution} }

################################################################################

=item $samples_per_pixel = $media->get_samples_per_pixel()

Returns the samples per pixel

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub get_samples_per_pixel { $_[0]->_get_image_info->{SamplesPerPixel} }
sub get_bits_per_sample { $_[0]->_get_image_info->{BitsPerSample} }
sub get_comment { $_[0]->_get_image_info->{Comment} }
sub get_interlace { $_[0]->_get_image_info->{Interlace} }
sub get_compression { $_[0]->_get_image_info->{Compression} }
sub get_gama { $_[0]->_get_image_info->{Gama} }
sub get_last_modi_time { $_[0]->_get_image_info->{LastModificationTime} }

################################################################################

################################################################################

################################################################################

=back

=head1 PRIVATE

=head2 Private Class Methods

NONE.

=head2 Private Instance Methods

NONE.

=head2 Private Functions

=over 4

=item $image_info = $self->_get_image_info_obj()

Returns the image info object.

B<Throws:>

NONE

B<Side Effects:>

NONE

B<Notes:>

NONE

=cut

sub _get_image_info {
    my ($self) = @_;
    my $info = $self->_get('_image_info');
    return $info if $info;
    $info = Image::Info::image_info( $self->_get('_path'));
    throw_dp(error => 'Error retrieving data from image.',
             payload => $info->{error})
      if $info->{error} && $info->{error} ne 'Unrecognized file format';
    $info->{resolution} = $info->{resolution}[0] if ref $info->{resolution};
    $self->_set({ '_image_info' => $info });
    return $info;
}

1;
__END__

=back

=head1 NOTES

NONE.

=head1 AUTHOR

David Wheeler <david@justatheory.com>

=head1 SEE ALSO

L<Bric|Bric>

=cut
