package Bric::Util::Grp::AssetLanguage;

our $VERSION = (qw$Revision: 1.1.1.1.2.1 $ )[-1];

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

sub get_class_id {
	# Get real ID
	return 26;
}

sub get_supported_classes {

	my $allowed_classes = { 
						'Bric::Util::Grp::AssetVersion'	=> 'grp'
						};
	return $allowed_classes;
}

__END__
