package Bric::Biz::Asset::Business::Story::Test;
use strict;
use warnings;
use base qw(Bric::Biz::Asset::Business::Test);
use Test::More;

my $CLASS = 'Bric::Biz::Asset::Business::Story';

##############################################################################
# Test class loading.
# NOTE: The tests load alphabetically, and this one has to be first.
##############################################################################
sub first_test_load: Test(3) {
    my $self = shift;
    $self->SUPER::_test_load;
    use_ok($CLASS);
}

1;
__END__
