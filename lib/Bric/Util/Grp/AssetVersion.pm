package Bric::Util::Grp::AssetVersion;

our $VERSION = substr(q$Revision: 1.1 $, 10, -1);

use strict;

use base qw(Bric::Util::Grp);


BEGIN {
	Bric::register_fields()
}


#sub new {
#	my $class = shift;
#
#	my $self = fields::new($class);
#
#	$self->SUPER::new();
#
#	$self->{'class_id'} = 1;
#
#	return $self;
#
#}

=item secret

Pod ME

=cut

sub get_secret {
	return 1;
}

=item Class ID

POD ME

=cut

sub get_class_id {
	return 25;
}


=item Supported Classes

POD ME

=cut

sub get_supported_classes {

	my $allowed_classes = { 
			       'Bric::Biz::Asset::Business::Media' => 'media',
			       'Bric::Biz::Asset::Business::Story'	=> 'story',
			       'Bric::Biz::Asset::Formatting' => 'formatting',
						};
	return $allowed_classes;
}

__END__
