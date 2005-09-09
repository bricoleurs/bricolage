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
        ({ element_type_id => 1 }), "Get Story OCs" );
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
    is( $oce->get_element_type_id, 1, "Check element_type_id eq 1" );
    ok( $oce->set_element_type_id(2), "Set element_type_id to 2" );
    is( $oce->get_element_type_id, 2, "Check element_type_id eq 2" );
}

##############################################################################
# Test the new() constructor.
sub test_new : Test(16) {
    my $self = shift;
    # Try creating one from an OC ID.
    ok( my $oce = Bric::Biz::OutputChannel::Element->new({oc_id => 1}),
        "Create OCE from OC ID 1" );
    isa_ok($oce, 'Bric::Biz::OutputChannel::Element');
    isa_ok($oce, 'Bric::Biz::OutputChannel');
    is( $oce->get_name, "Web", "Check name 'Web'" );

    ok( $oce = Bric::Biz::OutputChannel::Element->new({enabled => 1,
                                                       site_id => 100}),
        "Create enabled OC" );
    ok( $oce->is_enabled, "OC is enabled" );

    ok( $oce = Bric::Biz::OutputChannel::Element->new({enabled => 1,
                                                       site_id => 100}),
        "Create enabled OC" );
    ok( $oce->is_enabled, "Enabled OC is enabled" );

    ok( $oce = Bric::Biz::OutputChannel::Element->new({enabled => 0,
                                                       site_id => 100}),
        "Create disabled OC" );
    ok( ! $oce->is_enabled, "disabled OC is not enabled" );

    # Create a new output channel object.
    ok( my $oc = Bric::Biz::OutputChannel->new({ name => 'Foober',
                                                 site_id => 100 }),
        "Create new OC" );
    ok( $oc->save, "Save OC" );
    ok( my $ocid = $oc->get_id, "Get ID" );
    $self->add_del_ids([$ocid]);

    # Create a new OCElement.
    ok( $oce = Bric::Biz::OutputChannel::Element->new({ oc_id => $ocid }),
        "Create OCE from OC ID $ocid" );
    # It should not yet have a Map ID!
    ok(! defined $oce->_get('_map_id'), "Map ID is undefined" );
    # It should have only one group membership.
    my @gids = $oce->get_grp_ids;
    is( scalar @gids, 1, "Check for one group ID" );
}

##############################################################################
# Test instance methods.
##############################################################################
# Test save() method's update ability.
sub test_update : Test(13) {
    my $self = shift;
    # Grab an existing OCE from the database.
    ok( my $href = Bric::Biz::OutputChannel::Element->href
        ({ element_type_id => 1 }), "Get Story OCs" );
    ok( my $oce = $href->{1}, "Grab OC ID 1" );

    # Set enable to false.
    ok( $oce->is_enabled, "Check is_enabled" );
    ok( $oce->set_enabled_off, "Set enable off" );
    ok( $oce->save, "Save OCE" );

    # Look it up again.
    ok( $href = Bric::Biz::OutputChannel::Element->href
        ({ element_type_id => 1 }), "Get Story OCs again" );
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
    ok(my $oce = Bric::Biz::OutputChannel::Element->new({
        name       => "Foober",
        element_type_id => 1,
        site_id    => 100,
    }), "Create a brand new OCE" );

    # Now save it. It should be inserted as both an OC and as an OCE.
    ok( $oce->save, "Save new OCE" );
    ok( my $ocid = $oce->get_id, "Get ID" );
    $self->add_del_ids([$ocid]);

    # Now retreive it.
    ok( my $href = Bric::Biz::OutputChannel::Element->href
        ({ element_type_id => 1 }), "Get Story OCs" );
    ok( $oce = $href->{$ocid}, "Grab OC ID $ocid" );

    # Check its attributes.
    is( $oce->get_id, $ocid, "Check ID" );
    is( $oce->get_name, "Foober", "Check name 'Foober'" );

    # Now delete it.
    ok( $oce->remove, "Remove OCE" );
    ok( $oce->save, "Save removed OCE" );

    # Now try to retreive it.
    ok( $href = Bric::Biz::OutputChannel::Element->href
        ({ element_type_id => 1 }), "Get Story OCs" );
    ok( ! exists $href->{$ocid}, "ID $ocid gone" );
}

##############################################################################
# A concentrated test to make sure that the right OCE gets deleted no
# matter how many there are and which was changed most recently.
sub test_delete : Test(24) {
    my $self = shift;
    my @oces;
    # Create some OCE objects
    foreach my $name (qw(Gar GarGar GarGarGar Bar BarBar BarBarBar)) {
        ok( my $oce = Bric::Biz::OutputChannel::Element->new({
            name            => $name,
            element_type_id => 1,
            site_id         => 100,
        }), "Create OC '$name'" );

        # Now save it. It should be inserted as both an OC and as an OCE.
        ok( $oce->save, "Save OC '$name'" );
        $self->add_del_ids([$oce->get_id]);
        push @oces, $oce;
    }

    # Change and save the fourth OCE, so that it will be the most recently
    # updated, which might then cause PostgreSQL to return it instead of
    # another one.
    ok( $oces[3]->set_name('Ha Ha!'), "Set fourth OC name's to 'Ha Ha!'" );
    ok( $oces[3]->save, "Save OC 'Ha Ha!'" );

    # Try deleting the third OC.
    ok( my $testid = $oces[2]->get_id, "Get third OC's ID" );
    ok( $oces[2]->remove, "Remove third OC" );
    ok( $oces[2]->save, "Save third OC" );

    # Now get the hash ref of all output channels associated with element
    # ID 1.
    ok( my $href = Bric::Biz::OutputChannel::Element->href({
        element_type_id => 1
    }), "Get OC href" );

    ok( ! exists $href->{$testid}, "ID $testid gone" );

    # Now try deleting the first and see if we get the right one.
    ok( $testid = $oces[0]->get_id, "Get first OC's ID" );
    ok( $oces[0]->remove, "Remove first OC" );
    ok( $oces[0]->save, "Save first OC" );

    # Get the hash ref of all output channels associated with element ID 1
    # again.
    ok( $href = Bric::Biz::OutputChannel::Element->href({
        element_type_id => 1
    }), "Get OC href again" );

    ok( ! exists $href->{$testid}, "ID $testid gone" );
}

1;
__END__
