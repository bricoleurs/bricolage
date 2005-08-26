package Bric::Biz::AssetType::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Test::Exception;
use Bric::Biz::AssetType;
use Bric::Biz::OutputChannel;
use Bric::Biz::InputChannel;

my %elem = ( name          => 'Test Element',
             key_name      => 'test_element',
             description   => 'Testing Element API',
             burner        => Bric::Biz::AssetType::BURNER_MASON,
             type__id      => 1,
             reference     => 0,
             primary_oc_id => 1);

my $story_elem_id = 1;
my $column_elem_id = 2;

sub table { 'element' };

##############################################################################
# Test constructors.
##############################################################################
# Test new().
sub test_const : Test(8) {
    my $self = shift;

    my %elem = ( name => 'Test Element',
                 description => 'Testing Element API',
                 burner => Bric::Biz::AssetType->BURNER_MASON,
                 type__id => 1,
                 reference => 0);

    ok( my $elem = Bric::Biz::AssetType->new, "Create empty element" );
    isa_ok($elem, 'Bric::Biz::AssetType');
    isa_ok($elem, 'Bric');

    ok( $elem = Bric::Biz::AssetType->new(\%elem), "Create a new element");
    # Check a few of the attributes.
    is( $elem->get_name, $elem{name}, "Check name" );
    is( $elem->get_description, $elem{description}, "Check description" );
    is( $elem->get_burner, $elem{burner}, "Check burner" );
    is( $elem->get_type__id, $elem{type__id}, "Check type__id" );
}

##############################################################################
# Test the lookup() method.
sub test_lookup : Test(2) {
    my $self = shift;
    # Look up the ID in the delemabase.
    ok( my $elem = Bric::Biz::AssetType->lookup({ id => $story_elem_id }),
        "Look up story element" );
    is( $elem->get_id, $story_elem_id, "Check the elem ID is the same" );
}

##############################################################################
# Test the list() method.
sub test_list : Test(38) {
    my $self = shift;

    # Create a new element group.
    ok( my $grp = Bric::Util::Grp::AssetType->new
        ({ name => 'Test ElementGrp' }),
        "Create group" );

    # Create some test records.
    for my $n (1..5) {
        my %args = %elem;
        # Make sure the name is unique.
        $args{name}        .= $n;
        $args{key_name}    .= $n;
        $args{description} .= $n if $n % 2;
        ok( my $elem = Bric::Biz::AssetType->new(\%args), "Create $args{name}" );
        ok( $elem->save, "Save $args{name}" );
        # Save the ID for deleting.
        $self->add_del_ids([$elem->get_id]);
        $self->add_del_ids([$elem->get_at_grp__id], 'grp');
        $grp->add_member({ obj => $elem }) if $n % 2;
    }

    ok( $grp->save, "Save group" );
    ok( my $grp_id = $grp->get_id, "Get group ID" );
    $self->add_del_ids([$grp_id], 'grp');

    # Try name + wildcard.
    ok( my @elems = Bric::Biz::AssetType->list({ name => "$elem{name}%" }),
        "Look up name $elem{name}%" );
    is( scalar @elems, 5, "Check for 5 elements" );

    # Try description.
    ok( @elems = Bric::Biz::AssetType->list
        ({ description => "$elem{description}" }),
        "Look up description '$elem{description}'" );
    is( scalar @elems, 2, "Check for 2 elements" );

    # Try grp_id.
    my $all_grp_id = Bric::Biz::AssetType::INSTANCE_GROUP_ID;
    ok( @elems = Bric::Biz::AssetType->list({ grp_id => $grp_id }),
        "Look up grp_id $grp_id" );
    is( scalar @elems, 3, "Check for 3 elements" );
    # Make sure we've got all the Group IDs we think we should have.
    foreach my $elem (@elems) {
        my %grp_ids = map { $_ => 1 } @{ $elem->get_grp_ids };
        ok( $grp_ids{$all_grp_id} && $grp_ids{$grp_id},
          "Check for both IDs" );
    }

    # Try deactivating one group membership.
    ok( my $mem = $grp->has_member({ obj => $elems[0] }), "Get member" );
    ok( $mem->deactivate->save, "Deactivate and save member" );

    # Now there should only be two using grp_id.
    ok( @elems = Bric::Biz::AssetType->list({ grp_id => $grp_id }),
        "Look up grp_id $grp_id" );
    is( scalar @elems, 2, "Check for 2 elements" );

    # Try output channel.
    ok( @elems = Bric::Biz::AssetType->list({ output_channel => 1 }),
        "Lookup output channel 1" );
    # Make sure we have a whole bunch.
    is( scalar @elems, 6, "Check for 6 elements" );

    # Try input channel.
    ok( @elems = Bric::Biz::AssetType->list({ input_channel => 1 }),
        "Lookup input channel 1" );
    # Make sure we have a whole bunch.
    is( scalar @elems, 6, "Check for 6 elements" );    

    # Try data_name.
    ok( @elems = Bric::Biz::AssetType->list
        ({ data_name => "Deck" }),
        "Look up data_name 'Deck'" );
    is( scalar @elems, 3, "Check for 3 elements" );

    # Try type__id.
    ok( @elems = Bric::Biz::AssetType->list({ type__id => 2 }),
        "Look up type__id 2" );
    is( scalar @elems, 2, "Check for 2 elements" );

    # Try top_level
    ok( @elems = Bric::Biz::AssetType->list({ top_level => 1 }),
        "Look up top_level => 1" );
    is( scalar @elems, 11, "Check for 11 elements" );

    # Try media
    ok( @elems = Bric::Biz::AssetType->list({ media => 1 }),
        "Look up media => 1" );
    is( scalar @elems, 2, "Check for 2 elements" );
}

##############################################################################
# Test save().
sub test_save : Test(10) {
    my $self = shift;
    # Now create a new element.
    ok( my $elem = Bric::Biz::AssetType->new(\%elem), "Create a new element");

    # Add a new output channel.
    ok( my $oc = Bric::Biz::OutputChannel->new({ name => 'Foober',
                                                 site_id => 100 }),
        "Create 'Foober' OC" );
    ok( $oc->save, "Save Foober" );
    ok( my $ocid = $oc->get_id, "Get Foober ID" );
    $self->add_del_ids($ocid, 'output_channel');
    ok( $elem->add_output_channels([$oc]), "Add Foober" );
    
    # Add a new input channel.
    ok( my $ic = Bric::Biz::InputChannel->new({ key_name => 'Foober',
                                                name     => 'Foober',
                                                site_id  => 100 }),
        "Create 'Foober' IC" );
    ok( $ic->save, "Save Foober IC" );
    ok( my $icid = $ic->get_id, "Get Foober IC ID" );
    $self->add_del_ids($icid, 'input_channel');
    ok( $elem->add_input_channels([$ic]), "Add Foober IC" );

    # Save it.
    ok( $elem->save, "Save new element" );
    $self->add_del_ids($elem->get_id);
}

##############################################################################
# Test Output Channel methods.
##############################################################################
sub test_oc : Test(60) {
    my $self = shift;
    ok( my $at = Bric::Biz::AssetType->lookup({ id => $story_elem_id }),
        "Lookup story element" );

    # Try get_ocs.
    ok( my $oces = $at->get_output_channels, "Get existing OCs" );
    is( scalar @$oces, 1, "Check for one OC" );
    isa_ok($oces->[0], 'Bric::Biz::OutputChannel');
    isa_ok($oces->[0], 'Bric::Biz::OutputChannel::Element');
    is( $oces->[0]->get_name, "Web", "Check name 'Web'" );

    my $orig_oc_id = $oces->[0]->get_id;

    # Add a new output channel.
    ok( my $oc = Bric::Biz::OutputChannel->new({name    => 'Foober',
                                                site_id => 100}),
        "Create 'Foober' OC" );
    ok( $oc->save, "Save Foober" );
    ok( my $ocid = $oc->get_id, "Get Foober ID" );
    $self->add_del_ids($ocid, 'output_channel');

    # Add it to the Element object and try get_ocs again.
    ok( $at->add_output_channels([$oc]), "Add Foober" );
    ok( $oces = $at->get_output_channels, "Get existing OCs again" );
    is( scalar @$oces, 2, "Check for two OCs" );
    isa_ok($oces->[0], 'Bric::Biz::OutputChannel::Element');
    isa_ok($oces->[1], 'Bric::Biz::OutputChannel::Element');

    # Save the element object and try get_ocs again.
    ok( $at->save, "Save Story element" );
    ok( $oces = $at->get_output_channels, "Get existing OCs 3" );
    is( scalar @$oces, 2, "Check for two OCs again" );

    # Now lookup the story element from the database and try get_ocs again.
    ok( $at = Bric::Biz::AssetType->lookup({ id => $story_elem_id }),
        "Lookup story element again" );
    ok( $oces = $at->get_output_channels, "Get existing OCs 4" );
    is( scalar @$oces, 2, "Check for two OCs 3" );
    isa_ok($oces->[0], 'Bric::Biz::OutputChannel::Element');
    isa_ok($oces->[1], 'Bric::Biz::OutputChannel::Element');

    # Now try get_primary_oc_id() and set_primary_oc_id
    is( $at->get_primary_oc_id(100), $orig_oc_id,
        "Check that primary_oc_id is set to default site");
    is( $at->get_primary_oc_id(100), $orig_oc_id,
        "Check that primary_oc_id is second time too!");

    # Set the primary OC ID to the new value.
    $at->set_primary_oc_id($ocid, 100);
    is( $at->get_primary_oc_id(100), $ocid,
        "Check that it is reset after we set it");
    $at->save();
    is( $at->get_primary_oc_id(100), $ocid,
        "Check that it is reset after we save");

    # Make sure the new value persists after a save and lookup.
    ok( $at = Bric::Biz::AssetType->lookup({ id => $story_elem_id }),
        "Lookup story element again" );
    is( $at->get_primary_oc_id(100), $ocid,
        "Check that it is reset after we save");

    # Now try to delete the outputchannel when it is still selected
    throws_ok {
        $at->delete_output_channels([$oc]);
    } qr/Cannot delete a primary output channel/,
      "Check that you can't delete an output channel that is primary";

    # Restory the original primary OC ID.
    ok($at->set_primary_oc_id($orig_oc_id, 100), "Reset primary OC ID" );
    ok( $at->save, "Save restored primary OC ID" );

    # Now add the new output channel to the column element.
    ok( my $col = Bric::Biz::AssetType->lookup({ id => $column_elem_id }),
        "Lookup column element" );
    ok( $col->add_output_channels([$oc->get_id]), "Add Foober to column" );
    ok( $col->save, "Save column element" );

    # Look up column and make sure it has two output channels.
    ok( $col = Bric::Biz::AssetType->lookup({ id => $column_elem_id }),
        "Lookup column element again" );
    ok( $oces = $at->get_output_channels, "Get column OCs" );
    is( scalar @$oces, 2, "Check for two column OCs" );

    # Lookup the story element from the database again and try get_ocs again.
    ok( $at = Bric::Biz::AssetType->lookup({ id => $story_elem_id }),
        "Lookup story element again" );
    ok( $oces = $at->get_output_channels, "Get existing OCs 5" );
    is( scalar @$oces, 2, "Check for two OCs 3" );

    # Now delete it.
    my $i = 5;
    for my $e ($at, $col) {
        ok( $e->delete_output_channels([$oc->get_id]), "Delete OC" );
        ok( $oces = $e->get_output_channels, "Get existing OCs " . ++$i );
        is( scalar @$oces, 1, "Check for one OC again" );

        # Save the element object, then check the output channels again.
        ok( $e->save, "Save element" );
        ok( $oces = $e->get_output_channels, "Get existing OCs " . ++$i );
        is( scalar @$oces, 1, "Check for one OC 3" );

        # Now look it up and check it one last time.
        ok( $e = Bric::Biz::AssetType->lookup({ id => $e->get_id }),
            "Lookup element again" );
        ok( $oces = $e->get_output_channels, "Get existing OCs " . ++$i );
        is( scalar @$oces, 1, "Check for one OC 4" );
        is( $oces->[0]->get_name, "Web", "Check name 'Web' again" );
    }
}

##############################################################################
# Test Input Channel methods.
##############################################################################
sub test_ic : Test(60) {
    my $self = shift;
    ok( my $at = Bric::Biz::AssetType->lookup({ id => $story_elem_id }),
        "Lookup story element" );

    # Try get_input_channels.
    ok( my $ices = $at->get_input_channels, "Get existing ICs" );
    is( scalar @$ices, 1, "Check for one IC" );
    isa_ok($ices->[0], 'Bric::Biz::InputChannel');
    isa_ok($ices->[0], 'Bric::Biz::InputChannel::Element');
    is( $ices->[0]->get_name, "Default", "Check name 'Default'" );

    my $orig_ic_id = $ices->[0]->get_id;

    # Add a new input channel.
    ok( my $ic = Bric::Biz::InputChannel->new({name    => 'Foober',
                                               key_name => 'foober',
                                               site_id => 100}),
        "Create 'Foober' IC" );
    ok( $ic->save, "Save Foober" );
    ok( my $icid = $ic->get_id, "Get Foober ID" );
    $self->add_del_ids($icid, 'input_channel');

    # Add it to the Element object and try get_input_channels again.
    ok( $at->add_input_channels([$ic]), "Add Foober" );
    ok( $ices = $at->get_input_channels, "Get existing ICs again" );
    is( scalar @$ices, 2, "Check for two ICs" );
    isa_ok($ices->[0], 'Bric::Biz::InputChannel::Element');
    isa_ok($ices->[1], 'Bric::Biz::InputChannel::Element');

    # Save the element object and try get_input_channels again.
    ok( $at->save, "Save Story element" );
    ok( $ices = $at->get_input_channels, "Get existing ICs 3" );
    is( scalar @$ices, 2, "Check for two ICs again" );

    # Now lookup the story element from the database and try get_ics again.
    ok( $at = Bric::Biz::AssetType->lookup({ id => $story_elem_id }),
        "Lookup story element again" );
    ok( $ices = $at->get_input_channels, "Get existing ICs 4" );
    is( scalar @$ices, 2, "Check for two ICs 3" );
    isa_ok($ices->[0], 'Bric::Biz::InputChannel::Element');
    isa_ok($ices->[1], 'Bric::Biz::InputChannel::Element');

    # Now try get_primary_ic_id() and set_primary_ic_id
    is( $at->get_primary_ic_id(100), $orig_ic_id,
        "Check that primary_ic_id is set to default site");
    is( $at->get_primary_ic_id(100), $orig_ic_id,
        "Check that primary_ic_id is second time too!");

    # Set the primary IC ID to the new value.
    $at->set_primary_ic_id($icid, 100);
    is( $at->get_primary_ic_id(100), $icid,
        "Check that it is reset after we set it");
    $at->save();
    is( $at->get_primary_ic_id(100), $icid,
        "Check that it is reset after we save");

    # Make sure the new value persists after a save and lookup.
    ok( $at = Bric::Biz::AssetType->lookup({ id => $story_elem_id }),
        "Lookup story element again" );
    is( $at->get_primary_ic_id(100), $icid,
        "Check that it is reset after we save");

    # Now try to delete the input channel when it is still selected
    throws_ok {
        $at->delete_input_channels([$ic]);
    } qr/Cannot delete a primary input channel/,
      "Check that you can't delete an input channel that is primary";

    # Restory the original primary IC ID.
    ok($at->set_primary_ic_id($orig_ic_id, 100), "Reset primary OC ID" );
    ok( $at->save, "Save restored primary IC ID" );

    # Now add the new input channel to the column element.
    ok( my $col = Bric::Biz::AssetType->lookup({ id => $column_elem_id }),
        "Lookup column element" );
    ok( $col->add_input_channels([$ic->get_id]), "Add Foober to column" );
    ok( $col->save, "Save column element" );

    # Look up column and make sure it has two output channels.
    ok( $col = Bric::Biz::AssetType->lookup({ id => $column_elem_id }),
        "Lookup column element again" );
    ok( $ices = $at->get_input_channels, "Get column ICs" );
    is( scalar @$ices, 2, "Check for two column ICs" );

    # Lookup the story element from the database again and try get_ocs again.
    ok( $at = Bric::Biz::AssetType->lookup({ id => $story_elem_id }),
        "Lookup story element again" );
    ok( $ices = $at->get_input_channels, "Get existing ICs 5" );
    is( scalar @$ices, 2, "Check for two ICs 3" );

    # Now delete it.
    my $i = 5;
    for my $e ($at, $col) {
        ok( $e->delete_input_channels([$ic->get_id]), "Delete IC" );
        ok( $ices = $e->get_input_channels, "Get existing ICs " . ++$i );
        is( scalar @$ices, 1, "Check for one IC again" );

        # Save the element object, then check the input channels again.
        ok( $e->save, "Save element" );
        ok( $ices = $e->get_input_channels, "Get existing ICs " . ++$i );
        is( scalar @$ices, 1, "Check for one IC 3" );

        # Now look it up and check it one last time.
        ok( $e = Bric::Biz::AssetType->lookup({ id => $e->get_id }),
            "Lookup element again" );
        ok( $ices = $e->get_input_channels, "Get existing ICs " . ++$i );
        is( scalar @$ices, 1, "Check for one IC 4" );
        is( $ices->[0]->get_name, "Default", "Check name 'Default' again" );
    }
}


##############################################################################
# Test Site methods.
##############################################################################
sub test_site : Test(32) {
    my $self = shift;

    #dependant on intial values
    my ($top_level_element_id, $element_id) = (1,6);

    #create two dummy sites

    my $site1 = Bric::Biz::Site->new( { name => "Dummy 1",
                                        domain_name => 'www.dummy1.com',
                                      });

    ok( $site1->save(), "Create first dummy site");
    my $site1_id = $site1->get_id;
    $self->add_del_ids($site1_id, 'site');

    ok( my $ic1 = Bric::Biz::InputChannel->new({ key_name => __PACKAGE__ . "1",
                                                 name     => __PACKAGE__ . "1",
                                                 site_id  => $site1_id }),
        "Create IC1" );
    ok( $ic1->save, "Save IC1" );
    ok( my $ic1_id = $ic1->get_id, "Get IC ID1" );
    $self->add_del_ids($ic1_id, 'input_channel');

    ok( my $oc1 = Bric::Biz::OutputChannel->new({ name    => __PACKAGE__ . "1",
                                                 site_id => $site1_id }),
        "Create OC1" );
    ok( $oc1->save, "Save OC1" );
    ok( my $oc1_id = $oc1->get_id, "Get OC ID1" );
    $self->add_del_ids($oc1_id, 'output_channel');

    my $site2 = Bric::Biz::Site->new( { name => "Dummy 2",
                                        domain_name => 'www.dummy2.com',
                                      });


    ok( $site2->save(), "Create second dummy site");
    my $site2_id = $site2->get_id;
    $self->add_del_ids($site2_id, 'site');

    ok( my $ic2 = Bric::Biz::InputChannel->new({ key_name => __PACKAGE__ . "2",
                                                 name     => __PACKAGE__ . "2",
                                                 site_id  => $site2_id }),
        "Create IC2" );
    ok( $ic2->save, "Save IC2" );
    ok( my $ic2_id = $ic2->get_id, "Get IC ID2" );
    $self->add_del_ids($ic2_id, 'input_channel');

    ok( my $oc2 = Bric::Biz::OutputChannel->new({ name    => __PACKAGE__ . "2",
                                                 site_id => $site2_id }),
        "Create OC2" );
    ok( $oc2->save, "Save OC2" );
    ok( my $oc2_id = $oc2->get_id, "Get OC ID2" );
    $self->add_del_ids($oc2_id, 'output_channel');

    my $top_level_element = Bric::Biz::AssetType->lookup({id => $top_level_element_id});
    my $element           = Bric::Biz::AssetType->lookup({id => $element_id});

    #First of all test all exceptions

    throws_ok {
        $element->add_site($site1_id);
    } qr /Cannot add sites to non top-level elements/,
      "Check that only top_level objects can add a site";

    throws_ok {
        $element->add_site($site1);
    } qr /Cannot add sites to non top-level elements/,
      "Check that only top_level objects can add a site";

    throws_ok {
        $top_level_element->add_site(999999999); #Large ID that doesn't exist
    } qr /No such site/,  # ' trick
      "Check if site is a real site";

    throws_ok {
        $top_level_element->remove_sites([$site1]);
    } qr /Cannot remove last site from an element/,
      "Check that you can't remove the last site";

    is($site1->get_id, $top_level_element->add_site($site1)->get_id,
       "Add a new site");
    ok( $top_level_element->add_input_channels([$ic1_id]),
        "Associate IC1" );
    ok( $top_level_element->set_primary_ic_id($ic1_id, $site1_id),
        "Associate primary IC1" );
    ok( $top_level_element->add_output_channels([$oc1_id]),
        "Associate OC1" );
    ok( $top_level_element->set_primary_oc_id($oc1_id, $site1_id),
        "Associate primary OC1" );

    is($site2->get_id, $top_level_element->add_site($site2_id)->get_id, "Add a new site");
    ok( $top_level_element->add_input_channels([$ic2_id]),
        "Associate IC2" );
    ok( $top_level_element->add_output_channels([$oc2_id]),
        "Associate OC2" );
    ok( $top_level_element->set_primary_ic_id($ic2_id, $site2_id),
        "Associate primary IC2" );
    ok( $top_level_element->set_primary_oc_id($oc2_id, $site2_id),
        "Associate primary OC2" );

    #due to bug in the coll code, one must do a save between add_sites/remove_sites

    $top_level_element->save();

    is(scalar @{$top_level_element->get_sites()}, 3,
       "We should have three sites now");

    # Try to list elements based on site

    is(scalar @{Bric::Biz::AssetType->list({site_id => $site1_id,
                                            top_level => 1 })}, 1,
       "Check that list works with site_id as argument");

    $top_level_element->remove_sites([$site1, $site2_id]);

    $top_level_element->save();

    is(scalar @{Bric::Biz::AssetType->list({site_id => $site1_id,
                                            top_level => 1})}, 0,
       "Check that list works with site_id as argument");

    is(scalar @{$top_level_element->get_sites()}, 1,
       "We should have one site now");
}

1;
__END__
