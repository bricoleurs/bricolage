package Bric::Biz::OutputChannel::Element::DevTest;
use strict;
use warnings;
use base qw(Bric::Biz::OutputChannel::DevTest);
use Test::More;
use Bric::Biz::OutputChannel::Element;

##############################################################################
# Test constructors.
##############################################################################
# Test the href() constructor.
sub test_href : Test(12) {
    my $self = shift;
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
sub test_new : Test(10) {
    my $self = shift;
    # Try creating one from an OC ID.
    ok( my $oce = Bric::Biz::OutputChannel::Element->new({ oc_id => 1 }),
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

##############################################################################
# Test instance methods.
##############################################################################
# Test save() method's update ability.
sub test_update : Test(13) {
    my $self = shift;
    # Grab an existing OCE from the database.
    ok( my $href = Bric::Biz::OutputChannel::Element->href
        ({ element_id => 1 }), "Get Story OCs" );
    ok( my $oce = $href->{1}, "Grab OC ID 1" );

    # Set enable to false.
    ok( $oce->is_enabled, "Check is_enabled" );
    ok( $oce->set_enabled_off, "Set enable off" );
    ok( $oce->save, "Save OCE" );

    # Look it up again.
    ok( $href = Bric::Biz::OutputChannel::Element->href
        ({ element_id => 1 }), "Get Story OCs again" );
    ok( $oce = $href->{1}, "Grab OC ID 1 again" );

    # Enable should be false, now.
    ok( ! $oce->is_enabled, "Check is_enabled off" );
    ok( $oce->set_enabled_on, "Set enable on" );
    ok( $oce->save, "Save OCE again" );

    # Look it up one last time.
    ok( $href = Bric::Biz::OutputChannel::Element->href
        ({ element_id => 1 }), "Get Story OCs last" );
    ok( $oce = $href->{1}, "Grab OC ID 1 last" );
    ok( $oce->is_enabled, "Check is_enabled on again" );
}

##############################################################################
# Test save()'s insert and delete abilities.
sub test_insert : Test(11) {
    my $self = shift;
    # Create a new output channel.
    ok( my $oce = Bric::Biz::OutputChannel::Element->new({ name => "Foober",
                                                           element_id => 1
                                                         }),
      "Create a brand new OCE" );

    # Now save it. It should be inserted as both an OC and as an OCE.
    ok( $oce->save, "Save new OCE" );
    ok( my $ocid = $oce->get_id, "Get ID" );
    $self->add_del_ids([$ocid]);

    # Now retreive it.
    ok( my $href = Bric::Biz::OutputChannel::Element->href
        ({ element_id => 1 }), "Get Story OCs" );
    ok( $oce = $href->{$ocid}, "Grab OC ID $ocid" );

    # Check its attributes.
    is( $oce->get_id, $ocid, "Check ID" );
    is( $oce->get_name, "Foober", "Check name 'Foober'" );

    # Now delete it.
    ok( $oce->remove, "Remove OCE" );
    ok( $oce->save, "Save removed OCE" );

    # Now try to retreive it.
    ok( $href = Bric::Biz::OutputChannel::Element->href
        ({ element_id => 1 }), "Get Story OCs" );
    ok( ! exists $href->{$ocid}, "ID $ocid gone" );
}

1;
__END__
