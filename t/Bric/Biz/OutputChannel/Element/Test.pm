package Bric::Biz::OutputChannel::Element::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Biz::OutputChannel::Element');
}

##############################################################################
# Test the new() constructor.
sub test_new : Test(9) {
    ok( my $oce = Bric::Biz::OutputChannel::Element->new({site_id => 100}),
        "Create default OC" );
    isa_ok($oce, 'Bric::Biz::OutputChannel::Element');
    isa_ok($oce, 'Bric::Biz::OutputChannel');
    ok( $oce->is_enabled, "OC is enabled" );

    # Try creating one from an existing OC object.
    ok( my $oc = Bric::Biz::OutputChannel->new({name    => 'Foober',
                                                site_id => 100}),
        "Create new OC object" );
    ok( $oce = Bric::Biz::OutputChannel::Element->new({oc => $oc}),
        "Create OCE from OC" );
    isa_ok($oce, 'Bric::Biz::OutputChannel::Element');
    isa_ok($oce, 'Bric::Biz::OutputChannel');
    is( $oce->get_name, "Foober", "Check name 'Foober'" );

}

1;
__END__
