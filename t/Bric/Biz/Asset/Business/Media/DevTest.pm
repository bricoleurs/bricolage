package Bric::Biz::Asset::Business::Media::DevTest;
use strict;
use warnings;
use base qw(Bric::Biz::Asset::Business::DevTest);
use Test::More;
use Bric::Biz::Asset::Business::Media;

# Register this class for testing.
BEGIN { __PACKAGE__->test_class }

sub class { 'Bric::Biz::Asset::Business::Media' }

##############################################################################
# The element object we'll use throughout.
my $elem;
sub get_elem {
    $elem ||= Bric::Biz::AssetType->lookup({ id => 4 });
    $elem;
}

##############################################################################
# Arguments to the new() constructor. Used by construct().
sub new_args {
    my $self = shift;
    ( $self->SUPER::new_args,
      category__id => 0
    )
}



1;
__END__
