package Bric::Biz::Asset::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

# Register this class for testing.
BEGIN { __PACKAGE__->test_class }

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Biz::Asset');
}

1;
__END__
