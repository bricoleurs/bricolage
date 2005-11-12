package Bric::Biz::InputChannel::Element::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Biz::InputChannel::Element');
}

##############################################################################
# Test the new() constructor.
sub test_new : Test(9) {
    ok( my $ice = Bric::Biz::InputChannel::Element->new({site_id => 100}),
        "Create default IC" );
    isa_ok($ice, 'Bric::Biz::InputChannel::Element');
    isa_ok($ice, 'Bric::Biz::InputChannel');
    ok( $ice->is_enabled, "IC is enabled" );

    # Try creating one from an existing IC object.
    ok( my $ic = Bric::Biz::InputChannel->new({name    => 'Foober',
                                               site_id => 100}),
        "Create new IC object" );
    ok( $ice = Bric::Biz::InputChannel::Element->new({ic => $ic}),
        "Create ICE from IC" );
    isa_ok($ice, 'Bric::Biz::InputChannel::Element');
    isa_ok($ice, 'Bric::Biz::InputChannel');
    is( $ice->get_name, "Foober", "Check name 'Foober'" );

}

1;
__END__
