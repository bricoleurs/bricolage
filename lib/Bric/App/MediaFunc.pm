package Bric::App::MediaFunc;

=head1 NAME

Bric::App::MediaFunc - Location for functions that query uploaded media files.

=head1 VERSION

$Revision: 1.3 $

=cut

# Grab the Version Number.
our $VERSION = substr(q$Revision: 1.3 $, 10, -1);

=head1 DATE

$Date: 2001-10-03 19:32:14 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

################################################################################
# Dependencies
################################################################################
# Standard Dependencies
use strict;

################################################################################
# Programmatic Dependences
use Image::Info qw(image_info);

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
			_path				=> Bric::FIELD_NONE,
			_file_handle		=> Bric::FIELD_NONE,

			_image_info			=> Bric::FIELD_NONE
		});
}

################################################################################
# Class Methods
################################################################################

=head1 INTERFACE

=head2 Constructors

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

sub get_height {
	my ($self) = @_;

	my $info = $self->_get_image_info();

	return $info->{'height'};
}

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

sub get_width {
	my ($self) = @_;

	my $info = $self->_get_image_info();

	return $info->{'width'};
}

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

sub get_color_type {
	my ($self) = @_;

	my $info = $self->_get_image_info;

	return $info->{'color_type'};
}

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

sub get_resolution {
	my ($self) = @_;

	my $info = $self->_get_image_info;

	return $info->{'resolution'};
}

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

sub get_samples_per_pixel {
	my ($self) = @_;

	my $info = $self->_get_image_info;

	return $info->{'SamplesPerPixel'};
}

sub get_bits_per_sample {
	my ($self) = @_;

	my $info = $self->_get_image_info;

	return $info->{'BitsPerSample'};
}

sub get_comment {
	my ($self) = @_;

	my $info = $self->_get_image_info;

	return $info->{'Comment'};
}

sub get_interlace {
	my ($self) = @_;

	my $info = $self->_get_image_info;

	return $info->{'Interlace'};
}

sub get_comperssion {
	my ($self) = @_;

	my $info = $self->_get_image_info;
	return $info->{'Compression'};
}

sub get_gama {
	my ($self) = @_;

	my $info = $self->_get_image_info;

	return $info->{'Gama'};
}

sub get_last_modi_time {
	my ($self) = @_;

	my $info = $self->_get_image_info;

	return $info->{'LastModificationTime'};
}

################################################################################


sub test {
	my ($class, $fh) = @_;

	print STDERR "We have the file in media func\n";

	return "Eat More Cheese\n";
}

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

=item $image_info = $self->_get_image_info_obj()

Returns the iamge info object.

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

	$info = image_info( $self->_get('_path'));

	$self->_set( { '_image_info' => $info });

	return $info;
}

1;
__END__

=head1 NOTES

NONE.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=head1 SEE ALSO

perl(1),
Bric (2)

=head1 REVISION HISTORY

$Log: MediaFunc.pm,v $
Revision 1.3  2001-10-03 19:32:14  samtregar
Fixed errors that caused the server not to start after the merge from
Release_1_0.  It seems that these modules weren't returning true on
compilation.  I don't know if this was a an artifact of the merge or
indicative of a problem on the Release_1_0 branch.

Revision 1.2  2001/09/06 22:30:06  samtregar
Fixed remaining BL->App, BC->Biz conversions

Revision 1.1.1.1  2001/09/06 21:53:00  wheeler
Upload to SourceForge.

=cut
