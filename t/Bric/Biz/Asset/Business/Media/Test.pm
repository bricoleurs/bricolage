package Bric::Biz::Asset::Business::Media::Test;
use strict;
use warnings;
use base qw(Bric::Biz::Asset::Business::Test);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(+1) {
    my $self = shift;
    $self->SUPER::_test_load;
    use_ok('Bric::Biz::Asset::Business::Media');
}

1;
__END__
