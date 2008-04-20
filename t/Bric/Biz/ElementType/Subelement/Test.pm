package Bric::Biz::ElementType::Subelement::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Biz::ElementType::Subelement');
}

1;
__END__
