package Bric::Util::MediaType::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Util::MediaType;

##############################################################################
# Test class methods.
##############################################################################
# Test get_name_by_ext().
sub test_get_name_by_ext : Test(2) {
    my $self = shift;
    is( Bric::Util::MediaType->get_name_by_ext('foo.jpg'), 'image/jpeg',
        "Check image/jpeg" );
    is( Bric::Util::MediaType->get_name_by_ext('foo.jpeg'), 'image/jpeg',
        "Check image/jpeg" );
}

1;
__END__
