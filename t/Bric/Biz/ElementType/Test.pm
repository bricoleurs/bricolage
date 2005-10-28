package Bric::Biz::ElementType::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(2) {
    use_ok('Bric::Biz::ElementType::Parts::FieldType');
    use_ok('Bric::Biz::ElementType');
}

1;
__END__
