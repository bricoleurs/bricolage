package Bric::Biz::ElementType::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Test::Exception;
use Bric::Biz::ElementType;
use Bric::Biz::ATType;
use Bric::Biz::OutputChannel;
use Bric::Util::DBI qw(:junction);
use Bric::Biz::ElementType::Subelement;

my %elem = (
    name          => 'Test Element',
    key_name      => 'test_element',
    description   => 'Testing Element API',
    primary_oc_id => 1,
    top_level     => 1,
);

my $story_et_id    = 1;
my $column_et_id   = 2;
my $story_class_id = Bric::Biz::ElementType::STORY_CLASS_ID;
my $media_class_id = 46;
my $image_class_id = 50;

sub table { 'element_type' };

##############################################################################
# Test constructors.
##############################################################################
# Test new().
sub test_new : Test(24) {
    my $self = shift;

    my %et = (
        name        => 'Test ElementType',
        key_name    => 'test_element_type',
        description => 'Testing Element Type API',
    );

    ok( my $et = Bric::Biz::ElementType->new, 'Create empty element' );
    isa_ok($et, 'Bric::Biz::ElementType');
    isa_ok($et, 'Bric');

    ok( $et = Bric::Biz::ElementType->new(\%et), 'Create a new element');
    # Check a few of the attributes.
    is( $et->get_name, $et{name},               'Check name' );
    is( $et->get_key_name, $et{key_name},       'Check key_name' );
    is( $et->get_description, $et{description}, 'Check description' );

    # Test backwards compatibility with an ATType object.
    ok my $att = Bric::Biz::ATType->new({
        name      => 'Testing',
        top_level => 1,
        fixed_url => 1,
    }), 'Create a story element type';
    ok $att->save, 'Save story element type';
    $self->add_del_ids($att->get_id, 'at_type');

    ok $et = Bric::Biz::ElementType->new({
        %et,
        key_name => $et{key_name} . '+',
        type_id => $att->get_id,
    }), 'Create an element type with an ATType object';
    isa_ok($et, 'Bric::Biz::ElementType');
    isa_ok($et, 'Bric');
    is $et->get_type_id, $att->get_id, 'Should have the type ID';

    ok $et->save, 'Save the new element type';
    ok $et = Bric::Biz::ElementType->lookup({ id => $et->get_id }),
        'Look up the new element type';

    isa_ok($et, 'Bric::Biz::ElementType');
    isa_ok($et, 'Bric');
    is $et->get_type_id, $att->get_id, 'Should have the type ID';

    ok $et->is_fixed_uri,      'Should be fixed_uri';
    ok $et->is_top_level,      'Should be top level';
    ok !$et->is_related_story, 'Should not be related story';
    ok !$et->is_related_media, 'Should not be related media';
    ok !$et->is_paginated,     'Should not be paginated';
    ok !$et->is_media,         'Should not be media';
}

##############################################################################
# Test the lookup() method.
sub test_lookup : Test(2) {
    my $self = shift;
    # Look up the ID in the delemabase.
    ok( my $et = Bric::Biz::ElementType->lookup({ id => $story_et_id }),
        "Look up story element" );
    is( $et->get_id, $story_et_id, "Check the elem ID is the same" );
}

##############################################################################
# Test the list() method.
sub test_list : Test(69) {
    my $self = shift;

    # Create a new element group.
    ok( my $grp = Bric::Util::Grp::ElementType->new({
        name => 'Test ElementGrp'
    }), "Create group" );



    # Create some test records.
    for my $n (1..5) {
        my %args = %elem;
        # Make sure the name is unique.
        $args{name}        .= $n;
        $args{key_name}    .= $n;
        if ($n % 2) {
            # There'll be three of these.
            $args{description} .= $n;
            @args{qw(fixed_uri related_media related_story)} = (1,1,1);
        } else {
            # There'll be two of these.
            @args{qw(top_level media biz_class_id)} = (1,1,$media_class_id);
        }
        ok( my $elem = Bric::Biz::ElementType->new(\%args), "Create $args{name}" );
        ok( $elem->save, "Save $args{name}" );
        # Save the ID for deleting.
        $self->add_del_ids([$elem->get_id]);
        $grp->add_member({ obj => $elem }) if $n % 2;
    }

    ok( $grp->save, "Save group" );
    ok( my $grp_id = $grp->get_id, "Get group ID" );
    $self->add_del_ids([$grp_id], 'grp');

    # Try name + wildcard.
    ok( my @ets = Bric::Biz::ElementType->list({ name => "$elem{name}%" }),
        "Look up name $elem{name}%" );
    is( scalar @ets, 5, "Check for 5 elements" );
    isa_ok $_, 'Bric::Biz::ElementType' for @ets;

    # Try ANY(name).
    ok( @ets = Bric::Biz::ElementType->list({
        name => ANY("$elem{name}1", 'Inset')
    }), "Look up name ANY('$elem{name}1', 'Inset')" );
    is( scalar @ets, 2, "Check for 2 element types" );

    # Try ANY(ID).
    ok @ets = Bric::Biz::ElementType->list({
        id => ANY($ets[0]->get_id, $ets[1]->get_id )
    }), "Look up ANY(\@ids)";
    is( scalar @ets, 2, "Check for 2 element types" );

    # Try description.
    ok( @ets = Bric::Biz::ElementType->list
        ({ description => "$elem{description}" }),
        "Look up description '$elem{description}'" );
    is( scalar @ets, 2, "Check for 2 elements" );

    # Try description + wild card.
    ok( @ets = Bric::Biz::ElementType->list({
        description => "$elem{description}%"
    }), "Look up description '$elem{description}%'" );
    is( scalar @ets, 5, "Check for 5 element types" );

    # Try ANY(description).
    ok( @ets = Bric::Biz::ElementType->list({
        description => ANY($elem{description}, "$elem{description}1")
    }), "Look up description ANY('$elem{description}', '$elem{description}1'" );
    is( scalar @ets, 3, "Check for 3 element types" );


    # Try grp_id.
    my $all_grp_id = Bric::Biz::ElementType::INSTANCE_GROUP_ID;
    ok( @ets = Bric::Biz::ElementType->list({ grp_id => $grp_id }),
        "Look up grp_id $grp_id" );
    is( scalar @ets, 3, "Check for 3 elements" );
    # Make sure we've got all the Group IDs we think we should have.
    foreach my $elem (@ets) {
        my %grp_ids = map { $_ => 1 } @{ $elem->get_grp_ids };
        ok( $grp_ids{$all_grp_id} && $grp_ids{$grp_id},
          "Check for both IDs" );
    }

    # Try ANY(grp_id).
    ok( @ets = Bric::Biz::ElementType->list({ grp_id => ANY ($grp_id) }),
        "Look up grp_id ANY($grp_id)" );
    is( scalar @ets, 3, "Check for 3 element types" );

    # Try deactivating one group membership.
    ok( my $mem = $grp->has_member({ obj => $ets[0] }), "Get member" );
    ok( $mem->deactivate->save, "Deactivate and save member" );

    # Now there should only be two using grp_id.
    ok( @ets = Bric::Biz::ElementType->list({ grp_id => $grp_id }),
        "Look up grp_id $grp_id" );
    is( scalar @ets, 2, "Check for 2 element types" );

    # Try parent_id.
    my $et_id = 1;
    ok( @ets = Bric::Biz::ElementType->list({ parent_id => $et_id }),
        "Look up parent_id $et_id" );
    is( scalar @ets, 2, "Check for 2 subelements" );

    # Try child_id.
    $et_id = 10;
    ok( @ets = Bric::Biz::ElementType->list({ child_id => $et_id }),
        "Look up child_id $et_id" );
    is( scalar @ets, 3, "Check for 3 parents" );

    # Try active. There are 13 existing already.
    ok( @ets = Bric::Biz::ElementType->list({ active => 1 }),
        "Look up active => 1" );
    is( scalar @ets, 18, "Check for 18 element types" );

    # Try output channel.
    ok( @ets = Bric::Biz::ElementType->list({ output_channel => 1 }),
        "Lookup output channel 1" );
    # Make sure we have a whole bunch.
    is( scalar @ets, 6, "Check for 6 element types" );

    # Try data_name.
    ok( @ets = Bric::Biz::ElementType->list({
        data_name => "Deck"
    }), "Look up data_name 'Deck'" );
    is( scalar @ets, 3, "Check for 3 element types" );

    # Try ANY(data_name).
    ok( @ets = Bric::Biz::ElementType->list({
        data_name => ANY(qw(Deck Paragraph))
    }), 'Look up data_name ANY(qw(Deck Paragraph))');
    is( scalar @ets, 4, 'Check for 4 element types' );

    # Try fixed_uri, related_story, and related_media. There's one of each
    # already.
    foreach my $prop (qw(fixed_uri related_media related_story)) {
        ok( @ets = Bric::Biz::ElementType->list({ $prop => 1 }),
            "Look up $prop => 1" );
        is( scalar @ets, 4, "Check for 4 element types" );
    }

    # Try top_level
    ok( @ets = Bric::Biz::ElementType->list({ top_level => 1 }),
        "Look up top_level => 1" );
    is( scalar @ets, 11, "Check for 11 element types" );

    # Try media
    ok( @ets = Bric::Biz::ElementType->list({ media => 1 }),
        "Look up media => 1" );
    is( scalar @ets, 4, 'Check for 4 element types' );

    # Try media class type. There i one already.
    ok( @ets = Bric::Biz::ElementType->list({ biz_class_id => $media_class_id }),
        "Look up biz_class_id $media_class_id" );
    is( scalar @ets, 2, "Check for 1 element types" );

    # Try image class type.
    ok( @ets = Bric::Biz::ElementType->list({ biz_class_id => $image_class_id }),
        "Look up biz_class_id $image_class_id" );
    is( scalar @ets, 2, "Check for 2 element type" );

    # Try story and media class types.
    ok( @ets = Bric::Biz::ElementType->list({
        biz_class_id => ANY($story_class_id, $media_class_id),
    }), "Look up biz_class_id ANY($story_class_id, $media_class_id)" );
    is( scalar @ets, 16, "Check for 16 element types" );
}

##############################################################################
# Test class methods.
##############################################################################
# Test my_meths().
sub test_my_meths : Test(11) {
    ok( my $meths = Bric::Biz::ElementType->my_meths, "Get my_meths" );
    isa_ok($meths, 'HASH', "my_meths is a hash" );
    is( $meths->{name}{type}, 'short', "Check name type" );
    ok( $meths = Bric::Biz::ElementType->my_meths(1), "Get my_meths array ref" );
    isa_ok( $meths, 'ARRAY', "my_meths(1) is an array" );
    (is $meths->[0]->{name}, 'name', "Check first meth name" );

    # Try the identifier methods.
    ok( my $elem = Bric::Biz::ElementType->new({ key_name => 'new_at' }),
        "Create Element" );
    ok( my @meths = $elem->my_meths(0, 1), "Get ident meths" );
    is( scalar @meths, 1, "Check for 1 meth" );
    is( $meths[0]->{name}, 'key_name', "Check for 'key_name' meth" );
    is( $meths[0]->{get_meth}->($elem), 'new_at', "Check name 'new_at'" );
}

##############################################################################
# Test list_ids().
sub test_list_ids : Test(66) {
    my $self = shift;

    # Create a new element group.
    ok( my $grp = Bric::Util::Grp::ElementType->new({
        name => 'Test ElementGrp'
    }), "Create group" );

    # Create some test records.
    for my $n (1..5) {
        my %args = %elem;
        # Make sure the name is unique.
        $args{name}        .= $n;
        $args{key_name}    .= $n;
        if ($n % 2) {
            # There'll be three of these.
            $args{description} .= $n;
            @args{qw(fixed_uri related_media related_story)} = (1,1,1);
        } else {
            # There'll be two of these.
            @args{qw(top_level media biz_class_id)} = (1,1,$media_class_id);
        }
        ok( my $elem = Bric::Biz::ElementType->new(\%args), "Create $args{name}" );
        ok( $elem->save, "Save $args{name}" );
        # Save the ID for deleting.
        $self->add_del_ids([$elem->get_id]);
        $grp->add_member({ obj => $elem }) if $n % 2;
    }

    ok( $grp->save, "Save group" );
    ok( my $grp_id = $grp->get_id, "Get group ID" );
    $self->add_del_ids([$grp_id], 'grp');

    # Try name + wildcard.
    ok( my @et_ids = Bric::Biz::ElementType->list_ids({ name => "$elem{name}%" }),
        "Look up name $elem{name}%" );
    is( scalar @et_ids, 5, "Check for 5 elements" );
    like $_, qr/^\d+$/, "$_ should be an ID" for @et_ids;

    # Try ANY(name).
    ok( @et_ids = Bric::Biz::ElementType->list_ids({
        name => ANY("$elem{name}1", 'Inset')
    }), "Look up name ANY('$elem{name}1', 'Inset')" );
    is( scalar @et_ids, 2, "Check for 2 element type IDs" );

    # Try ANY(ID).
    ok @et_ids = Bric::Biz::ElementType->list_ids({
        id => ANY(@et_ids[0..1])
    }), "Look up ANY(\@ids)";
    is( scalar @et_ids, 2, "Check for 2 element type IDs" );

    # Try description.
    ok( @et_ids = Bric::Biz::ElementType->list_ids
        ({ description => "$elem{description}" }),
        "Look up description '$elem{description}'" );
    is( scalar @et_ids, 2, "Check for 2 elements" );

    # Try description + wild card.
    ok( @et_ids = Bric::Biz::ElementType->list_ids({
        description => "$elem{description}%"
    }), "Look up description '$elem{description}%'" );
    is( scalar @et_ids, 5, "Check for 5 element type IDs" );

    # Try ANY(description).
    ok( @et_ids = Bric::Biz::ElementType->list_ids({
        description => ANY($elem{description}, "$elem{description}1")
    }), "Look up description ANY('$elem{description}', '$elem{description}1'" );
    is( scalar @et_ids, 3, "Check for 3 element type IDs" );

    # Try parent_id.
    my $et_id = 1;
    ok( @et_ids = Bric::Biz::ElementType->list_ids({ parent_id => $et_id }),
        "Look up parent_id $et_id" );
    is( scalar @et_ids, 2, "Check for 2 subelements" );

    # Try child_id.
    $et_id = 10;
    ok( @et_ids = Bric::Biz::ElementType->list_ids({ child_id => $et_id }),
        "Look up child_id $et_id" );
    is( scalar @et_ids, 3, "Check for 3 parents" );

    # Try grp_id.
    my $all_grp_id = Bric::Biz::ElementType::INSTANCE_GROUP_ID;
    ok( @et_ids = Bric::Biz::ElementType->list_ids({ grp_id => $grp_id }),
        "Look up grp_id $grp_id" );
    is( scalar @et_ids, 3, "Check for 3 elements" );

    # Try ANY(grp_id).
    ok( @et_ids = Bric::Biz::ElementType->list_ids({ grp_id => ANY ($grp_id) }),
        "Look up grp_id ANY($grp_id)" );
    is( scalar @et_ids, 3, "Check for 3 element type IDs" );

    # Try deactivating one group membership.
    ok( my $mem = $grp->has_member({
        id => $et_ids[0],
        package => 'Bric::Biz::ElementType'
    }), "Get member" );
    ok( $mem->deactivate->save, "Deactivate and save member" );

    # Now there should only be two using grp_id.
    ok( @et_ids = Bric::Biz::ElementType->list_ids({ grp_id => $grp_id }),
        "Look up grp_id $grp_id" );
    is( scalar @et_ids, 2, "Check for 2 element type IDs" );

    # Try active. There are 13 existing already.
    ok( @et_ids = Bric::Biz::ElementType->list_ids({ active => 1 }),
        "Look up active => 1" );
    is( scalar @et_ids, 18, "Check for 18 element type IDs" );

    # Try output channel.
    ok( @et_ids = Bric::Biz::ElementType->list_ids({ output_channel => 1 }),
        "Lookup output channel 1" );
    # Make sure we have a whole bunch.
    is( scalar @et_ids, 6, "Check for 6 element type IDs" );

    # Try data_name.
    ok( @et_ids = Bric::Biz::ElementType->list_ids({
        data_name => "Deck"
    }), "Look up data_name 'Deck'" );
    is( scalar @et_ids, 3, "Check for 3 element type IDs" );

    # Try ANY(data_name).
    ok( @et_ids = Bric::Biz::ElementType->list_ids({
        data_name => ANY(qw(Deck Paragraph))
    }), 'Look up data_name ANY(qw(Deck Paragraph))');
    is( scalar @et_ids, 4, 'Check for 4 element type IDs' );

    # Try fixed_uri, related_story, and related_media. There's one of each
    # already.
    foreach my $prop (qw(fixed_uri related_media related_story)) {
        ok( @et_ids = Bric::Biz::ElementType->list_ids({ $prop => 1 }),
            "Look up $prop => 1" );
        is( scalar @et_ids, 4, "Check for 4 element type IDs" );
    }

    # Try top_level
    ok( @et_ids = Bric::Biz::ElementType->list_ids({ top_level => 1 }),
        "Look up top_level => 1" );
    is( scalar @et_ids, 11, "Check for 11 element type IDs" );

    # Try media
    ok( @et_ids = Bric::Biz::ElementType->list_ids({ media => 1 }),
        "Look up media => 1" );
    is( scalar @et_ids, 4, 'Check for 4 element type IDs' );

    # Try media class type. There i one already.
    ok( @et_ids = Bric::Biz::ElementType->list_ids({ biz_class_id => $media_class_id }),
        "Look up biz_class_id $media_class_id" );
    is( scalar @et_ids, 2, "Check for 1 element type IDs" );

    # Try image class type.
    ok( @et_ids = Bric::Biz::ElementType->list_ids({ biz_class_id => $image_class_id }),
        "Look up biz_class_id $image_class_id" );
    is( scalar @et_ids, 2, "Check for 2 element type ID" );

    # Try story and media class types.
    ok( @et_ids = Bric::Biz::ElementType->list_ids({
        biz_class_id => ANY($story_class_id, $media_class_id),
    }), "Look up biz_class_id ANY($story_class_id, $media_class_id)" );
    is( scalar @et_ids, 16, "Check for 16 element type IDs" );
}

##############################################################################
# Test save().
sub test_save : Test(6) {
    my $self = shift;
    # Now create a new element.
    ok( my $elem = Bric::Biz::ElementType->new(\%elem), "Create a new element");

    # Add a new output channel.
    ok( my $oc = Bric::Biz::OutputChannel->new({ name => 'Foober',
                                                 site_id => 100 }),
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
sub test_oc : Test(60) {
    my $self = shift;
    ok( my $at = Bric::Biz::ElementType->lookup({ id => $story_et_id }),
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
    ok( $at = Bric::Biz::ElementType->lookup({ id => $story_et_id }),
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
    ok( $at = Bric::Biz::ElementType->lookup({ id => $story_et_id }),
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
    ok( my $col = Bric::Biz::ElementType->lookup({ id => $column_et_id }),
        "Lookup column element" );
    ok( $col->add_output_channels([$oc->get_id]), "Add Foober to column" );
    ok( $col->save, "Save column element" );

    # Look up column and make sure it has two output channels.
    ok( $col = Bric::Biz::ElementType->lookup({ id => $column_et_id }),
        "Lookup column element again" );
    ok( $oces = $at->get_output_channels, "Get column OCs" );
    is( scalar @$oces, 2, "Check for two column OCs" );

    # Lookup the story element from the database again and try get_ocs again.
    ok( $at = Bric::Biz::ElementType->lookup({ id => $story_et_id }),
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
        ok( $e = Bric::Biz::ElementType->lookup({ id => $e->get_id }),
            "Lookup element again" );
        ok( $oces = $e->get_output_channels, "Get existing OCs " . ++$i );
        is( scalar @$oces, 1, "Check for one OC 4" );
        is( $oces->[0]->get_name, "Web", "Check name 'Web' again" );
    }
}

##############################################################################
# Test Site methods.
##############################################################################
sub test_site : Test(26) {
    my $self = shift;

    #dependant on intial values
    my ($top_level_element_id, $element_id) = (1,6);

    #create two dummy sites
    ok my $site1 = Bric::Biz::Site->new({
        name => "Dummy 1",
        domain_name => 'www.dummy1.com',
    }), 'create first dummy site';

    ok $site1->save, "Save first dummy site";
    my $site1_id = $site1->get_id;
    $self->add_del_ids($site1_id, 'site');

    ok my $oc1 = Bric::Biz::OutputChannel->new({
        name    => __PACKAGE__ . "1",
        site_id => $site1_id 
    }), 'Create OC';
    ok $oc1->save, 'Save OC1';
    ok my $oc1_id = $oc1->get_id, "Get OC ID1";
    $self->add_del_ids($oc1_id, 'output_channel');

    ok my $site2 = Bric::Biz::Site->new({
        name => "Dummy 2",
        domain_name => 'www.dummy2.com',
    }), 'Create second dummy site';


    ok $site2->save(), "Save second dummy site";
    my $site2_id = $site2->get_id;
    $self->add_del_ids($site2_id, 'site');

    ok my $oc2 = Bric::Biz::OutputChannel->new({
        name    => __PACKAGE__ . "2",
        site_id => $site2_id
    }), 'Create OC2';
    ok $oc2->save, 'Save OC2';
    ok my $oc2_id = $oc2->get_id, 'Get OC ID2';
    $self->add_del_ids($oc2_id, 'output_channel');

    my $top_level_element = Bric::Biz::ElementType->lookup({
        id => $top_level_element_id
    });
    my $element = Bric::Biz::ElementType->lookup({id => $element_id});

    #First of all test all exceptions
    throws_ok {
        $element->add_site($site1_id);
    } qr /Cannot add sites to non top-level element types/,
      "Check that only top_level objects can add a site";

    throws_ok {
        $element->add_site($site1);
    } qr /Cannot add sites to non top-level element types/,
      'Check that only top_level objects can add a site';

    throws_ok {
        $top_level_element->add_site(-1); # Negative ID that doesn't exist
    } qr /No such site/,
      'Check if site is a real site';

    throws_ok {
        $top_level_element->remove_sites([$site1]);
    } qr /Cannot remove last site from an element/,
      'Check that you cannot remove the last site';

    is $site1->get_id, $top_level_element->add_site($site1)->get_id,
        'Add a new site';
    ok $top_level_element->add_output_channels([$oc1_id]),
        'Associate OC1';
    ok $top_level_element->set_primary_oc_id($oc1_id, $site1_id),
        'Associate primary OC1';

    is $site2->get_id, $top_level_element->add_site($site2_id)->get_id,
        'Add a new site';
    ok $top_level_element->add_output_channels([$oc2_id]),
        'Associate OC2';
    ok $top_level_element->set_primary_oc_id($oc2_id, $site2_id),
        'Associate primary OC2';

    #due to bug in the coll code, one must do a save between add_sites/remove_sites
    $top_level_element->save();

    is scalar @{$top_level_element->get_sites()}, 3,
        'We should have three sites now';

    # Try to list elements based on site
    is scalar @{Bric::Biz::ElementType->list({
        site_id   => $site1_id,
        top_level => 1
    })}, 1, 'Check that list works with site_id as argument';

    ok $top_level_element->remove_sites([$site1, $site2_id]),
        'Remove two sites from the top level element';

    ok $top_level_element->save, 'Save the top level element';

    is scalar @{Bric::Biz::ElementType->list({
        site_id => $site1_id,
        top_level => 1
    })}, 0, 'Check that list works with site_id as argument';

    is scalar @{$top_level_element->get_sites()}, 1,
        'We should have one site now';
}

##############################################################################
# Make sure that subelement types and fields work properly.
sub test_subelement_types : Test(57) {
    my $self = shift;

    # Create an output channel.
    ok my $oc = Bric::Biz::OutputChannel->new({
        name    => 'Test XHTML',
        site_id => 100,
    }), "Create an output channel";
    ok $oc->save, "Save the new output channel";
    $self->add_del_ids($oc->get_id, 'output_channel');
    ok $oc->save, "Save the new output channel with its includes";

    # Create a story type.
    ok my $story_type = Bric::Biz::ElementType->new({
        key_name  => '_testing_',
        name      => 'Testing',
        top_level => 1,
    }), "Create story type";
    ok $story_type->add_site(100), "Add the site ID";
    ok $story_type->add_output_channels([$oc]), "Add the output channel";
    ok $story_type->set_primary_oc_id($oc->get_id, 100),
      "Set it as the primary OC";;
    ok $story_type->save, "Save the test story type";
    $self->add_del_ids($story_type->get_id, 'element_type');

    # Give it a header field.
    ok my $head = $story_type->new_field_type({
        key_name    => 'header',
        name        => 'Header',
        min_occurrence => 0,
        max_occurrence => 0,
        sql_type    => 'short',
        place       => 1,
        max_length  => 0, # Unlimited
    }), "Add a field";

    # Give it a paragraph field.
    ok my $para = $story_type->new_field_type({
        key_name    => 'para',
        name        => 'Paragraph',
        min_occurrence  => 0,
        max_occurrence  => 0,
        sql_type    => 'short',
        place       => 2,
        max_length  => 0, # Unlimited
    }), "Add a field";

    # Save the story type with its fields.
    ok $story_type->save, "Save element with the fields";
    $self->add_del_ids($head->get_id, 'field_type');
    $self->add_del_ids($para->get_id, 'field_type');

    # Create a subelement.
    ok my $pull_quote = Bric::Biz::ElementType->new({
        key_name  => '_pull_quote_',
        name      => 'Pull Quote',
    }), "Create a subelement element";

    ok $pull_quote->save, "Save the subelement element";
    $self->add_del_ids($pull_quote->get_id, 'element_type');

    # Give it a paragraph field.
    ok my $pq_para = $pull_quote->new_field_type({
        key_name    => 'para',
        name        => 'Paragraph',
        min_occurrence    => 1,
        max_occurrence  => 1,
        sql_type    => 'short',
        place       => 1,
        max_length  => 0, # Unlimited
    }), "Add a field";

    # Give it a by field.
    ok my $by = $pull_quote->new_field_type({
        key_name    => 'by',
        name        => 'By',
        min_occurrence    => 1,
        max_occurrence  => 1,
        sql_type    => 'short',
        place       => 2,
        max_length  => 0, # Unlimited
    }), "Add a field";

    # Give it a date field.
    ok my $date = $pull_quote->new_field_type({
        key_name    => 'date',
        name        => 'Date',
        min_occurrence    => 1,
        max_occurrence  => 1,
        sql_type    => 'date',
        place       => 3,
        max_length  => 0, # Unlimited
    }), "Add a field";

    # Save the pull quote with its fields.
    ok $pull_quote->save, "Save subelement with the fields";
    $self->add_del_ids($pq_para->get_id, 'field_type');
    $self->add_del_ids($by->get_id, 'field_type');
    $self->add_del_ids($date->get_id, 'field_type');

    # Create a page subelement.
    ok my $page = Bric::Biz::ElementType->new({
        key_name  => '_page_',
        name      => 'Page',
        top_level => 0,
        paginated => 1,
    }), "Create a page subelement element";

    # Give it a paragraph field.
    ok my $page_para = $page->new_field_type({
        key_name    => 'para',
        name        => 'Paragraph',
        min_occurrence  => 0,
        max_occurrence  => 1,
        sql_type    => 'short',
        place       => 1,
        max_length  => 0, # Unlimited
    }), "Add a field";

    # Save it.
    ok $page->save, "Save the page subelement element";
    $self->add_del_ids($page->get_id, 'element_type');

    # Add the subelements to the story type element.
    ok $story_type->add_containers([$pull_quote->get_id, $page->get_id]),
      "Add the subelements";
    ok $story_type->save, 'Save the story type with its subelements';

    # Now let's look it up again.
    ok $story_type = Bric::Biz::ElementType->lookup({
        id => $story_type->get_id
    }), 'Look up the story type';

    # Get its subelement field types.
    ok my @fts = $story_type->get_field_types,
        'Get the storye type\'s field types';
    is scalar @fts, 2, 'There should be two field types';
    is $fts[0]->get_key_name, 'header', '... The first should be header';
    is $fts[1]->get_key_name, 'para', '... The second should be paragraph';


    # Get its subelement container types.
    # XXX Eventually we should be able to order these.
    # Test the get_containers with a ids specified
    ok my @conts = $story_type->get_containers($pull_quote->get_id, $page->get_id),
      'Get the story type\'s containers with the id\'s';
    is scalar @conts, 2, 'There should be two containers';
    my %subs = map { $_->get_key_name => $_} @conts;
    ok $subs{_pull_quote_}, '... One should be a pull quote';
    ok $subs{_page_}, '... The other should be a page';

    # Test the get_containers with a single id specified
    ok @conts = $story_type->get_containers($pull_quote->get_id),
      'Get the story type\'s container with a single id';
    is scalar @conts, 1, 'There should be one containers';
    %subs = map { $_->get_key_name => $_} @conts;
    ok $subs{_pull_quote_}, '... One should be a pull quote';


    # Test the get_containers with the keyname specified
    ok my $cont_et = $story_type->get_containers($page->get_key_name),
      'Get the story type\'s container with the key name.';
    is $cont_et->get_key_name, '_page_', "Make sure it's a page";

    # Just get all of them
    ok @conts = $story_type->get_containers,
        'Get the story type\'s containers';
    is scalar @conts, 2, 'There should be two containers';
    %subs = map { $_->get_key_name => $_} @conts;
    ok $subs{_pull_quote_}, '... One should be a pull quote';
    ok $subs{_page_}, '... The other should be a page';

    # Test deleting one of them
    ok $story_type->del_containers($page->get_id), "Delete the page container";
    ok @conts = $story_type->get_containers,
        'Get the story type\'s containers';
    is scalar @conts, 1, 'There should be one container left';
    %subs = map { $_->get_key_name => $_} @conts;
    ok $subs{_pull_quote_}, '... It should be a pull quote';

    # Put it back
    ok $story_type->add_containers($page->get_id), "Put the container back";
    ok @conts = $story_type->get_containers,
        'Get the story type\'s containers';
    is scalar @conts, 2, 'There should be two containers';
    %subs = map { $_->get_key_name => $_} @conts;
    ok $subs{_pull_quote_}, '... One should be a pull quote';
    ok $subs{_page_}, '... The other should be a page';

    # Try the subelements' subelements.
    ok my @subs = $subs{_pull_quote_}->get_field_types,
        'Get the pull quote field types';
    is scalar @subs, 3, 'There should be three field types';
    my %pq_subs = map { $_->get_key_name => $_} @subs;
    ok $pq_subs{para}, '... One should be a paragraph';
    ok $pq_subs{by}, '... Another should be a by line';
    ok $pq_subs{date}, '... The third should be a date';

    ok @subs = $subs{_page_}->get_field_types,
        'Get the page field types';
    is scalar @subs, 1, 'There should be one field type';
    is $subs[0]->get_key_name, 'para', '... And it should be a paragraph';
}

1;
__END__
