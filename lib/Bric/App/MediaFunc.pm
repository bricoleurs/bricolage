package Bric::App::MediaFunc;

=head1 Name

Bric::App::MediaFunc - Location for functions that query uploaded media files.

=cut

# Grab the Version Number.
require Bric; our $VERSION = Bric->VERSION;

=head1 Synopsis

TBD.

=head1 Description

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
    Bric::register_fields({
        _path         => Bric::FIELD_NONE,
        _file_handle => Bric::FIELD_NONE,
        _image_info     => Bric::FIELD_NONE
    });
}

################################################################################
# Class Methods
################################################################################

=head1 Interface

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

=item $height = $media_func->get_height

Returns the height of the image.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Throws:> NONE.

=cut

################################################################################

=item $width = $media->get_width

Returns the width of the image.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

################################################################################

=item $color_type = $media->get_color_type

Returns the color type of the image.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

################################################################################

=item $resolution = $media->get_resolution()

Returns the resolution of the image.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

################################################################################

=item $samples_per_pixel = $media->get_samples_per_pixel()

Returns the samples per pixel in the image.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

################################################################################

=item $bits_per_sample = $media->get_bits_per_sample

Returns the bits per sample in the image.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

################################################################################

=item $comment = $media->get_comment

Returns the image comment.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

################################################################################

=item $interlace = $media->get_interlace

Returns the image interlace.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

################################################################################

=item $compression = $media->get_compression

Returns the image compression.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

################################################################################

=item $gama = $media->get_gama

Returns the image gama.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

################################################################################

=item $last_modi_time = $media->get_last_modi_time

Returns the last modification time of the image.

B<Throws:> NONE.

B<Side Effects:> NONE.

B<Notes:> NONE.

=cut

for my $spec (
    ['height'],
    ['width'],
    ['color_type'],
    ['resolution'],
    [ samples_per_pixel => 'SamplesPerPixel' ],
    [ bits_per_sample   => 'BitsPerSample' ],
    [ comment           => 'Comment' ],
    [ interlace         => 'Interlace' ],
    [ compression       => 'Compression' ],
    [ gama              => 'Gama' ],
    [ last_modi_time    => 'LastModificationTime' ],
) {
    my ($attr, $get) = @$spec;
    $get ||= $attr;
    no strict 'refs';
    *{"get_$attr"} = sub {
        my $ret = shift->_get_image_info->{$get};
        return ref $ret ? $ret->[0] : $ret;
    };
}

###############################################################################

################################################################################

=back

=head1 Private

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
    $self->_set({ '_image_info' => $info });
    return $info;
}

1;
__END__

=back

=head1 Notes

NONE.

=head1 Author

David Wheeler <david@justatheory.com>

=head1 See Also

L<Bric|Bric>

=cut
