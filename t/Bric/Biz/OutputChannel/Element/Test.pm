package Bric::Biz::OutputChannel::Element::Test;
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
    use_ok('Bric::Biz::OutputChannel::Element');
}

##############################################################################
# Test constructors.
##############################################################################
# Test the href() constructor.
sub test_href : Test(12) {
    ok( my $href = Bric::Biz::OutputChannel::Element->href
        ({ element_id => 1 }), "Get Story OCs" );
    is( scalar keys %$href, 1, "Check for one OC" );
    ok( my $oce = $href->{1}, "Grab OC ID 1" );
    is( $oce->get_name, 'Web', "Check OC name 'Web'" );

    # Check the enabled attribute.
    ok( $oce->is_enabled, "Check is_enabled" );
    ok( $oce->set_enabled_off, "Turn enabled off" );
    ok( ! $oce->is_enabled, "Check is_enabled off" );
    ok( $oce->set_enabled_on, "Turn enabled on" );
    ok( $oce->is_enabled, "Check is_enabled on" );

    # Check the element_id attribute.
    is( $oce->get_element_id, 1, "Check element_id eq 1" );
    ok( $oce->set_element_id(2), "Set element_id to 2" );
    is( $oce->get_element_id, 2, "Check element_id eq 2" );
}

##############################################################################
# Test the new() constructor.
sub test_new : Test(19) {
    ok( my $oce = Bric::Biz::OutputChannel::Element->new,
        "Create default OC" );
    isa_ok($oce, 'Bric::Biz::OutputChannel::Element');
    isa_ok($oce, 'Bric::Biz::OutputChannel');
    ok( $oce->is_enabled, "OC is enabled" );

    # Try creating one from an existing OC object.
    ok( my $oc = Bric::Biz::OutputChannel->new({ name => 'Foober'}),
        "Create new OC object" );
    ok( $oce = Bric::Biz::OutputChannel::Element->new({ oc => $oc }),
        "Create OCE from OC" );
    isa_ok($oce, 'Bric::Biz::OutputChannel::Element');
    isa_ok($oce, 'Bric::Biz::OutputChannel');
    is( $oce->get_name, "Foober", "Check name 'Foober'" );

    # Try creating one from an OC ID.
    ok( $oce = Bric::Biz::OutputChannel::Element->new({ oc_id => 1 }),
        "Create OCE from OC ID 1" );
    isa_ok($oce, 'Bric::Biz::OutputChannel::Element');
    isa_ok($oce, 'Bric::Biz::OutputChannel');
    is( $oce->get_name, "Web", "Check name 'Web'" );

    ok( $oce = Bric::Biz::OutputChannel::Element->new({ enabled => 1 }),
        "Create enabled OC" );
    ok( $oce->is_enabled, "OC is enabled" );

    ok( $oce = Bric::Biz::OutputChannel::Element->new({ enabled => 1 }),
        "Create enabled OC" );
    ok( $oce->is_enabled, "Enabled OC is enabled" );

    ok( $oce = Bric::Biz::OutputChannel::Element->new({ enabled => 0 }),
        "Create disabled OC" );
    ok( ! $oce->is_enabled, "disabled OC is not enabled" );
}
