package Bric::Biz::AssetType::Parts::Data::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Biz::AssetType::Parts::Data');
}

1;
__END__
