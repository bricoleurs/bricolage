package Bric::Biz::AssetType::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Biz::AssetType;
use Bric::Biz::OutputChannel;

my %elem = ( name => 'Test Element',
             description => 'Testing Element API',
             burner => Bric::Biz::AssetType::BURNER_MASON,
             type__id => 1,
             reference => 0,
             primary_oc_id => 1);

my $story_elem_id = 1;
my $column_elem_id = 2;

sub table { 'element' };

##############################################################################
# Test constructors.
##############################################################################
# Test new().
sub test_const : Test(9) {
    my $self = shift;

    my %elem = ( name => 'Test Element',
                 description => 'Testing Element API',
                 burner => Bric::Biz::AssetType->BURNER_MASON,
                 type__id => 1,
                 reference => 0,
                 primary_oc_id => 1);

    ok( my $elem = Bric::Biz::AssetType->new, "Create empty element" );
    isa_ok($elem, 'Bric::Biz::AssetType');
    isa_ok($elem, 'Bric');

    ok( $elem = Bric::Biz::AssetType->new(\%elem), "Create a new element");
    # Check a few of the attributes.
    is( $elem->get_name, $elem{name}, "Check name" );
    is( $elem->get_description, $elem{description}, "Check description" );
    is( $elem->get_burner, $elem{burner}, "Check burner" );
    is( $elem->get_type__id, $elem{type__id}, "Check type__id" );
    is( $elem->get_primary_oc_id, $elem{primary_oc_id},
        "Check primary_oc_id" );
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
sub test_list : Test(36) {
    my $self = shift;

    # Create a new element group.
    ok( my $grp = Bric::Util::Grp::AssetType->new
        ({ name => 'Test ElementGrp' }),
        "Create group" );

    # Create some test records.
    for my $n (1..5) {
        my %args = %elem;
        # Make sure the name is unique.
        $args{name} .= $n;
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
sub test_save : Test(6) {
    my $self = shift;
    # Now create a new element.
    ok( my $elem = Bric::Biz::AssetType->new(\%elem), "Create a new element");

    # Add a new output channel.
    ok( my $oc = Bric::Biz::OutputChannel->new({ name => 'Foober' }),
        "Create 'Foober' OC" );
    ok( $oc->save, "Save Foober" );
    ok( my $ocid = $oc->get_id, "Get Foober ID" );
    $self->add_del_ids($ocid, 'output_channel');
    ok( $elem->add_output_channels([$oc]), "Add Foober" );

    # Save it.
    ok( $elem->save, "Save new element" );
    $self->add_del_ids($elem->get_id);
}

##############################################################################
# Test Output Channel methods.
##############################################################################
sub test_oc : Test(51) {
    my $self = shift;
    ok( my $at = Bric::Biz::AssetType->lookup({ id => $story_elem_id }),
        "Lookup story element" );

    # Try get_ocs.
    ok( my $oces = $at->get_output_channels, "Get existing OCs" );
    is( scalar @$oces, 1, "Check for one OC" );
    isa_ok($oces->[0], 'Bric::Biz::OutputChannel');
    isa_ok($oces->[0], 'Bric::Biz::OutputChannel::Element');
    is( $oces->[0]->get_name, "Web", "Check name 'Web'" );

    # Add a new output channel.
    ok( my $oc = Bric::Biz::OutputChannel->new({ name => 'Foober' }),
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

    # Now add the new output channel to the column element.
    ok( my $col = Bric::Biz::AssetType->lookup({ id => $column_elem_id }),
        "Lookup column element" );
    ok( $col->add_output_channels([$oc]), "Add Foober to column" );
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
        ok( $e->delete_output_channels([$oc]), "Delete OC" );
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

1;
__END__
