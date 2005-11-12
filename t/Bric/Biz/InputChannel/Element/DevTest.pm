package Bric::Biz::InputChannel::Element::DevTest;
use strict;
use warnings;
use base qw(Bric::Biz::InputChannel::DevTest);
use Test::More;
use Bric::Biz::InputChannel::Element;

##############################################################################
# Test constructors.
##############################################################################
# Test the href() constructor.
sub test_href : Test(12) {
    my $self = shift;
    ok( my $href = Bric::Biz::InputChannel::Element->href
        ({ element_type_id => 1 }), "Get Story ICs" );
    is( scalar keys %$href, 1, "Check for one IC" );
    ok( my $ice = $href->{1}, "Grab IC ID 1" );
    is( $ice->get_name, 'Default', "Check IC name 'Default'" );

    # Check the enabled attribute.
    ok( $ice->is_enabled, "Check is_enabled" );
    ok( $ice->set_enabled_off, "Turn enabled off" );
    ok( ! $ice->is_enabled, "Check is_enabled off" );
    ok( $ice->set_enabled_on, "Turn enabled on" );
    ok( $ice->is_enabled, "Check is_enabled on" );

    # Check the element_id attribute.
    is( $ice->get_element_type_id, 1, "Check element_type_id eq 1" );
    ok( $ice->set_element_type_id(2), "Set element_type_id to 2" );
    is( $ice->get_element_type_id, 2, "Check element_type_id eq 2" );
}

##############################################################################
# Test the new() constructor.
sub test_new : Test(16) {
    my $self = shift;
    # Try creating one from an IC ID.
    ok( my $ice = Bric::Biz::InputChannel::Element->new({ic_id => 1}),
        "Create ICE from IC ID 1" );
    isa_ok($ice, 'Bric::Biz::InputChannel::Element');
    isa_ok($ice, 'Bric::Biz::InputChannel');
    is( $ice->get_name, "Default", "Check name 'Default'" );

    ok( $ice = Bric::Biz::InputChannel::Element->new({enabled => 1,
                                                       site_id => 100}),
        "Create enabled IC" );
    ok( $ice->is_enabled, "IC is enabled" );

    ok( $ice = Bric::Biz::InputChannel::Element->new({enabled => 1,
                                                       site_id => 100}),
        "Create enabled IC" );
    ok( $ice->is_enabled, "Enabled IC is enabled" );

    ok( $ice = Bric::Biz::InputChannel::Element->new({enabled => 0,
                                                       site_id => 100}),
        "Create disabled IC" );
    ok( ! $ice->is_enabled, "disabled IC is not enabled" );

    # Create a new input channel object.
    ok( my $ic = Bric::Biz::InputChannel->new({ name => 'Foober',
                                                 site_id => 100 }),
        "Create new IC" );
    ok( $ic->save, "Save IC" );
    ok( my $icid = $ic->get_id, "Get ID" );
    $self->add_del_ids([$icid]);

    # Create a new ICElement.
    ok( $ice = Bric::Biz::InputChannel::Element->new({ ic_id => $icid }),
        "Create ICE from IC ID $icid" );
    # It should not yet have a Map ID!
    ok(! defined $ice->_get('_map_id'), "Map ID is undefined" );
    # It should have only one group membership.
    my @gids = $ice->get_grp_ids;
    is( scalar @gids, 1, "Check for one group ID" );
}

##############################################################################
# Test instance methods.
##############################################################################
# Test save() method's update ability.
sub test_update : Test(13) {
    my $self = shift;
    # Grab an existing ICE from the database.
    ok( my $href = Bric::Biz::InputChannel::Element->href
        ({ element_type_id => 1 }), "Get Story ICs" );
    ok( my $ice = $href->{1}, "Grab IC ID 1" );

    # Set enable to false.
    ok( $ice->is_enabled, "Check is_enabled" );
    ok( $ice->set_enabled_off, "Set enable off" );
    ok( $ice->save, "Save ICE" );

    # Look it up again.
    ok( $href = Bric::Biz::InputChannel::Element->href
        ({ element_type_id => 1 }), "Get Story ICs again" );
    ok( $ice = $href->{1}, "Grab IC ID 1 again" );

    # Enable should be false, now.
    ok( ! $ice->is_enabled, "Check is_enabled off" );
    ok( $ice->set_enabled_on, "Set enable on" );
    ok( $ice->save, "Save ICE again" );

    # Look it up one last time.
    ok( $href = Bric::Biz::InputChannel::Element->href
        ({ element_id => 1 }), "Get Story ICs last" );
    ok( $ice = $href->{1}, "Grab IC ID 1 last" );
    ok( $ice->is_enabled, "Check is_enabled on again" );
}

##############################################################################
# Test save()'s insert and delete abilities.
sub test_insert : Test(11) {
    my $self = shift;
    # Create a new input channel.
    ok(my $ice = Bric::Biz::InputChannel::Element->new({
        name       => "Foober",
        element_type_id => 1,
        site_id    => 100,
    }), "Create a brand new ICE" );

    # Now save it. It should be inserted as both an IC and as an ICE.
    ok( $ice->save, "Save new ICE" );
    ok( my $icid = $ice->get_id, "Get ID" );
    $self->add_del_ids([$icid]);

    # Now retreive it.
    ok( my $href = Bric::Biz::InputChannel::Element->href
        ({ element_type_id => 1 }), "Get Story ICs" );
    ok( $ice = $href->{$icid}, "Grab IC ID $icid" );

    # Check its attributes.
    is( $ice->get_id, $icid, "Check ID" );
    is( $ice->get_name, "Foober", "Check name 'Foober'" );

    # Now delete it.
    ok( $ice->remove, "Remove ICE" );
    ok( $ice->save, "Save removed ICE" );

    # Now try to retreive it.
    ok( $href = Bric::Biz::InputChannel::Element->href
        ({ element_type_id => 1 }), "Get Story ICs" );
    ok( ! exists $href->{$icid}, "ID $icid gone" );
}

##############################################################################
# A concentrated test to make sure that the right ICE gets deleted no
# matter how many there are and which was changed most recently.
sub test_delete : Test(24) {
    my $self = shift;
    my @ices;
    # Create some ICE objects
    foreach my $name (qw(Gar GarGar GarGarGar Bar BarBar BarBarBar)) {
        ok( my $ice = Bric::Biz::InputChannel::Element->new({
            name            => $name,
            element_type_id => 1,
            site_id         => 100,
        }), "Create IC '$name'" );

        # Now save it. It should be inserted as both an IC and as an ICE.
        ok( $ice->save, "Save IC '$name'" );
        $self->add_del_ids([$ice->get_id]);
        push @ices, $ice;
    }

    # Change and save the fourth ICE, so that it will be the most recently
    # updated, which might then cause PostgreSQL to return it instead of
    # another one.
    ok( $ices[3]->set_name('Ha Ha!'), "Set fourth IC name's to 'Ha Ha!'" );
    ok( $ices[3]->save, "Save IC 'Ha Ha!'" );

    # Try deleting the third IC.
    ok( my $testid = $ices[2]->get_id, "Get third IC's ID" );
    ok( $ices[2]->remove, "Remove third IC" );
    ok( $ices[2]->save, "Save third IC" );

    # Now get the hash ref of all input channels associated with element
    # ID 1.
    ok( my $href = Bric::Biz::InputChannel::Element->href({
        element_type_id => 1
    }), "Get IC href" );

    ok( ! exists $href->{$testid}, "ID $testid gone" );

    # Now try deleting the first and see if we get the right one.
    ok( $testid = $ices[0]->get_id, "Get first IC's ID" );
    ok( $ices[0]->remove, "Remove first IC" );
    ok( $ices[0]->save, "Save first IC" );

    # Get the hash ref of all input channels associated with element ID 1
    # again.
    ok( $href = Bric::Biz::InputChannel::Element->href({
        element_type_id => 1
    }), "Get IC href again" );

    ok( ! exists $href->{$testid}, "ID $testid gone" );
}

1;
__END__
