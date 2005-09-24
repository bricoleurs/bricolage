package Bric::Biz::ElementType::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Test::Exception;
use Bric::Biz::ElementType;
use Bric::Biz::OutputChannel;

my %elem = ( name          => 'Test Element',
             key_name      => 'test_element',
             description   => 'Testing Element API',
             burner        => Bric::Biz::ElementType::BURNER_MASON,
             type_id       => 1,
             reference     => 0,
             primary_oc_id => 1);

my $story_elem_id = 1;
my $column_elem_id = 2;

sub table { 'element_type' };

##############################################################################
# Test constructors.
##############################################################################
# Test new().
sub test_const : Test(8) {
    my $self = shift;

    my %elem = (
        name        => 'Test Element',
        description => 'Testing Element API',
        burner      => Bric::Biz::ElementType->BURNER_MASON,
        type_id     => 1,
        reference   => 0
    );

    ok( my $elem = Bric::Biz::ElementType->new, "Create empty element" );
    isa_ok($elem, 'Bric::Biz::ElementType');
    isa_ok($elem, 'Bric');

    ok( $elem = Bric::Biz::ElementType->new(\%elem), "Create a new element");
    # Check a few of the attributes.
    is( $elem->get_name, $elem{name}, "Check name" );
    is( $elem->get_description, $elem{description}, "Check description" );
    is( $elem->get_burner, $elem{burner}, "Check burner" );
    is( $elem->get_type_id, $elem{type_id}, "Check type_id" );
}

##############################################################################
# Test the lookup() method.
sub test_lookup : Test(2) {
    my $self = shift;
    # Look up the ID in the delemabase.
    ok( my $elem = Bric::Biz::ElementType->lookup({ id => $story_elem_id }),
        "Look up story element" );
    is( $elem->get_id, $story_elem_id, "Check the elem ID is the same" );
}

##############################################################################
# Test the list() method.
sub test_list : Test(36) {
    my $self = shift;

    # Create a new element group.
    ok( my $grp = Bric::Util::Grp::ElementType->new
        ({ name => 'Test ElementGrp' }),
        "Create group" );

    # Create some test records.
    for my $n (1..5) {
        my %args = %elem;
        # Make sure the name is unique.
        $args{name}        .= $n;
        $args{key_name}    .= $n;
        $args{description} .= $n if $n % 2;
        ok( my $elem = Bric::Biz::ElementType->new(\%args), "Create $args{name}" );
        ok( $elem->save, "Save $args{name}" );
        # Save the ID for deleting.
        $self->add_del_ids([$elem->get_id]);
        $self->add_del_ids([$elem->get_et_grp_id], 'grp');
        $grp->add_member({ obj => $elem }) if $n % 2;
    }

    ok( $grp->save, "Save group" );
    ok( my $grp_id = $grp->get_id, "Get group ID" );
    $self->add_del_ids([$grp_id], 'grp');

    # Try name + wildcard.
    ok( my @elems = Bric::Biz::ElementType->list({ name => "$elem{name}%" }),
        "Look up name $elem{name}%" );
    is( scalar @elems, 5, "Check for 5 elements" );

    # Try description.
    ok( @elems = Bric::Biz::ElementType->list
        ({ description => "$elem{description}" }),
        "Look up description '$elem{description}'" );
    is( scalar @elems, 2, "Check for 2 elements" );

    # Try grp_id.
    my $all_grp_id = Bric::Biz::ElementType::INSTANCE_GROUP_ID;
    ok( @elems = Bric::Biz::ElementType->list({ grp_id => $grp_id }),
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
    ok( @elems = Bric::Biz::ElementType->list({ grp_id => $grp_id }),
        "Look up grp_id $grp_id" );
    is( scalar @elems, 2, "Check for 2 elements" );

    # Try output channel.
    ok( @elems = Bric::Biz::ElementType->list({ output_channel => 1 }),
        "Lookup output channel 1" );
    # Make sure we have a whole bunch.
    is( scalar @elems, 6, "Check for 6 elements" );

    # Try data_name.
    ok( @elems = Bric::Biz::ElementType->list
        ({ data_name => "Deck" }),
        "Look up data_name 'Deck'" );
    is( scalar @elems, 3, "Check for 3 elements" );

    # Try type_id.
    ok( @elems = Bric::Biz::ElementType->list({ type_id => 2 }),
        "Look up type_id 2" );
    is( scalar @elems, 2, "Check for 2 elements" );

    # Try top_level
    ok( @elems = Bric::Biz::ElementType->list({ top_level => 1 }),
        "Look up top_level => 1" );
    is( scalar @elems, 11, "Check for 11 elements" );

    # Try media
    ok( @elems = Bric::Biz::ElementType->list({ media => 1 }),
        "Look up media => 1" );
    is( scalar @elems, 2, "Check for 2 elements" );
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
    ok( my $at = Bric::Biz::ElementType->lookup({ id => $story_elem_id }),
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
    ok( $at = Bric::Biz::ElementType->lookup({ id => $story_elem_id }),
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
    ok( $at = Bric::Biz::ElementType->lookup({ id => $story_elem_id }),
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
    ok( my $col = Bric::Biz::ElementType->lookup({ id => $column_elem_id }),
        "Lookup column element" );
    ok( $col->add_output_channels([$oc->get_id]), "Add Foober to column" );
    ok( $col->save, "Save column element" );

    # Look up column and make sure it has two output channels.
    ok( $col = Bric::Biz::ElementType->lookup({ id => $column_elem_id }),
        "Lookup column element again" );
    ok( $oces = $at->get_output_channels, "Get column OCs" );
    is( scalar @$oces, 2, "Check for two column OCs" );

    # Lookup the story element from the database again and try get_ocs again.
    ok( $at = Bric::Biz::ElementType->lookup({ id => $story_elem_id }),
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
sub test_site : Test(22) {
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

    ok( my $oc2 = Bric::Biz::OutputChannel->new({ name    => __PACKAGE__ . "2",
                                                 site_id => $site2_id }),
        "Create OC2" );
    ok( $oc2->save, "Save OC2" );
    ok( my $oc2_id = $oc2->get_id, "Get OC ID2" );
    $self->add_del_ids($oc2_id, 'output_channel');

    my $top_level_element = Bric::Biz::ElementType->lookup({id => $top_level_element_id});
    my $element           = Bric::Biz::ElementType->lookup({id => $element_id});

    #First of all test all exceptions

    throws_ok {
        $element->add_site($site1_id);
    } qr /Cannot add sites to non top-level element types/,
      "Check that only top_level objects can add a site";

    throws_ok {
        $element->add_site($site1);
    } qr /Cannot add sites to non top-level element types/,
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
    ok( $top_level_element->add_output_channels([$oc1_id]),
        "Associate OC1" );
    ok( $top_level_element->set_primary_oc_id($oc1_id, $site1_id),
        "Associate primary OC1" );

    is($site2->get_id, $top_level_element->add_site($site2_id)->get_id, "Add a new site");
    ok( $top_level_element->add_output_channels([$oc2_id]),
        "Associate OC2" );
    ok( $top_level_element->set_primary_oc_id($oc2_id, $site2_id),
        "Associate primary OC2" );

    #due to bug in the coll code, one must do a save between add_sites/remove_sites

    $top_level_element->save();

    is(scalar @{$top_level_element->get_sites()}, 3,
       "We should have three sites now");

    # Try to list elements based on site

    is(scalar @{Bric::Biz::ElementType->list({site_id => $site1_id,
                                            top_level => 1 })}, 1,
       "Check that list works with site_id as argument");

    $top_level_element->remove_sites([$site1, $site2_id]);

    $top_level_element->save();

    is(scalar @{Bric::Biz::ElementType->list({site_id => $site1_id,
                                            top_level => 1})}, 0,
       "Check that list works with site_id as argument");

    is(scalar @{$top_level_element->get_sites()}, 1,
       "We should have one site now");
}

##############################################################################
# Make sure that subelement types and fields work properly.
sub test_subelement_types : Test(45) {
    my $self = shift;

    # Create an output channel.
    ok my $oc = Bric::Biz::OutputChannel->new({
        name    => 'Test XHTML',
        site_id => 100,
    }), "Create an output channel";
    ok $oc->save, "Save the new output channel";
    $self->add_del_ids($oc->get_id, 'output_channel');
    ok $oc->save, "Save the new output channel with its includes";

    # First, we'll need a story element type set.
    ok my $story_et = Bric::Biz::ATType->new({
        name      => 'Testing',
        top_level => 1,
    }), "Create a story element type";
    ok $story_et-> save, "Save story element type";
    $self->add_del_ids($story_et->get_id, 'at_type');

    # Next, a subelement set.
    ok my $sub_et = Bric::Biz::ATType->new({
        name      => 'Subby',
        top_level => 0,
    }), "Create a subelement element type";
    ok $sub_et-> save, "Save subelement element type";
    $self->add_del_ids($sub_et->get_id, 'at_type');

    # And finally, a page subelement set.
    ok my $page_et = Bric::Biz::ATType->new({
        name      => 'Pagey',
        top_level => 0,
        paginated => 1,
    }), "Create a page element type";
    ok $page_et-> save, "Save page element type";
    $self->add_del_ids($page_et->get_id, 'at_type');

    # Create a story type.
    ok my $story_type = Bric::Biz::ElementType->new({
        key_name  => '_testing_',
        name      => 'Testing',
        burner    => Bric::Biz::ElementType::BURNER_MASON,
        type__id  => $story_et->get_id,
        reference => 0, # No idea what this is.
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
        required    => 0,
        quantifier  => 1,
        sql_type    => 'short',
        place       => 1,
        publishable => 1, # Huh?
        max_length  => 0, # Unlimited
    }), "Add a field";

    # Give it a paragraph field.
    ok my $para = $story_type->new_field_type({
        key_name    => 'para',
        name        => 'Paragraph',
        required    => 0,
        quantifier  => 1,
        sql_type    => 'short',
        place       => 2,
        publishable => 1, # Huh?
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
        burner    => Bric::Biz::ElementType::BURNER_MASON,
        type__id  => $sub_et->get_id,
        reference => 0, # No idea what this is.
    }), "Create a subelement element";

    ok $pull_quote->save, "Save the subelement element";
    $self->add_del_ids($pull_quote->get_id, 'element_type');

    # Give it a paragraph field.
    ok my $pq_para = $pull_quote->new_field_type({
        key_name    => 'para',
        name        => 'Paragraph',
        required    => 1,
        quantifier  => 0,
        sql_type    => 'short',
        place       => 1,
        publishable => 1, # Huh?
        max_length  => 0, # Unlimited
    }), "Add a field";

    # Give it a by field.
    ok my $by = $pull_quote->new_field_type({
        key_name    => 'by',
        name        => 'By',
        required    => 1,
        quantifier  => 0,
        sql_type    => 'short',
        place       => 2,
        publishable => 1, # Huh?
        max_length  => 0, # Unlimited
    }), "Add a field";

    # Give it a date field.
    ok my $date = $pull_quote->new_field_type({
        key_name    => 'date',
        name        => 'Date',
        required    => 1,
        quantifier  => 0,
        sql_type    => 'date',
        place       => 3,
        publishable => 1, # Huh?
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
        burner    => Bric::Biz::ElementType::BURNER_MASON,
        type__id  => $page_et->get_id,
        reference => 0, # No idea what this is.
    }), "Create a page subelement element";

    # Give it a paragraph field.
    ok my $page_para = $page->new_field_type({
        key_name    => 'para',
        name        => 'Paragraph',
        required    => 0,
        quantifier  => 0,
        sql_type    => 'short',
        place       => 1,
        publishable => 1, # Huh?
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
    ok my @conts = $story_type->get_containers,
        'Get the storye type\'s containers';
    is scalar @conts, 2, 'There should be two containers';
    my %subs = map { $_->get_key_name => $_} @conts;
    ok $subs{_pull_quote_}, '... One shoudl be a pull quote';
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
