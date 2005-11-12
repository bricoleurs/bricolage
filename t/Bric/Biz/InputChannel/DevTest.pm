package Bric::Biz::InputChannel::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Biz::InputChannel;
use Bric::Util::Grp::InputChannel;

sub table { 'input_channel' }

my %ic = ( name        => 'Bogus',
           description => 'Bogus IC',
           site_id     => 100,
         );
my $ic_id = 1;

##############################################################################
# Clean out possible test values from InputChannel.tst. We can delete this if
# we ever delete the .tst files.
##############################################################################
sub _clean_test_vals : Test(startup) {
    my $self = shift;
    $self->add_del_ids([2, 3, 4]);
}

##############################################################################
# Test constructors.
##############################################################################
# Test the lookup() method.
sub test_lookup : Test(7) {
    ok( my $ic = Bric::Biz::InputChannel->lookup({ id => $ic_id}),
        "Lookup default IC" );

    # Make sure it's a good IC.
    isa_ok($ic, 'Bric::Biz::InputChannel');
    isa_ok($ic, 'Bric');

    # Check its properties.
    is ($ic->get_name,        'Default',               "Check name" );
    is ($ic->get_description, 'Default input channel', "Check description" );
    is ($ic->get_site_id,     100,                     'Check site ID');
    ok ($ic->is_active,       "Check is_active" );
}

##############################################################################
# Test the list() method.
sub test_list : Test(44) {
    my $self = shift;
    # Create a new input channel group.
    ok( my $grp = Bric::Util::Grp::InputChannel->new
        ({name => 'Test IC Grp'}), "Create group" );

    # Look up the default "Web" group.
    ok( my $ic = Bric::Biz::InputChannel->lookup({id => $ic_id}),
        "Look up default IC" );

    # Create some test records.
    for my $n (1..5) {
        my %args = %ic;
        # Make sure the name is unique.
        $args{name}   .= $n;
        
        if ($n % 2) {
            $args{description} .= $n;
        }
        
        ok( my $ic2 = Bric::Biz::InputChannel->new(\%args),
            "Create $args{name}" );
        ok( $ic2->save, "Save $args{name}" );
        
        # Save the ID for deleting.
        $self->add_del_ids($ic2->get_id);
        $grp->add_member({ obj => $ic2 }) if $n % 2;;
    }

    # Save the group.
    ok( $grp->save, "Save group" );
    ok( my $grp_id = $grp->get_id, "Get group ID" );
    $self->add_del_ids($grp_id, 'grp');

    # Save the IC.
    ok( $ic->save, "Save default IC" );

    # Start with the "name" attribute.
    ok(my @ics = Bric::Biz::InputChannel->list({ name => 'Default'}),
       "List name 'Default'" );
    is(scalar @ics, 1, "Check name number = 1");
    is($ics[0]->get_name, 'Default', "Check name 'Default'" );
    @ics = Bric::Biz::InputChannel->list({ name => 'foo'});
    ok(!@ics, "List name 'foo' has no results");

    # Try name + wildcard.
    ok( @ics = Bric::Biz::InputChannel->list({ name => "$ic{name}%" }),
        "Look up name $ic{name}%" );
    is( scalar @ics, 5, "Check for 5 input channels" );

    # Try the "description" attribute.
    ok(@ics = Bric::Biz::InputChannel->list
       ({ description => 'Default input channel'}),
       "List desc 'Default input channel'" );
    is(scalar @ics, 1, "Check desc number");
    is($ics[0]->get_description, 'Default input channel',
       "Check desc 'Default input channel'" );
    @ics = Bric::Biz::InputChannel->list({ description => 'foo'});
    ok(!@ics, "List desc 'foo' has no results");

    # Try description again.
    ok( @ics = Bric::Biz::InputChannel->list
        ({ description => "$ic{description}" }),
        "Look up description '$ic{description}'" );
    is( scalar @ics, 2, "Check for 2 input channels" );

    # Try description with wild card.
    ok( @ics = Bric::Biz::InputChannel->list
        ({ description => "$ic{description}%" }),
        "Look up description '$ic{description}%'" );
    is( scalar @ics, 5, "Check for 5 input channels" );

    # Try site_id
    ok (@ics = Bric::Biz::InputChannel->list({site_id => $ic{site_id}}),
        "Look up site '$ic{site_id}'");
    is (scalar @ics, 6, "Check for 6 input channels" );

    # Try grp_id.
    ok( @ics = Bric::Biz::InputChannel->list({ grp_id => $grp_id }),
        "Look up grp_id $grp_id" );
    is( scalar @ics, 3, "Check for 3 input channels" );

    # Make sure we've got all the Group IDs we think we should have.
    my $all_grp_id = Bric::Biz::InputChannel::INSTANCE_GROUP_ID;
    foreach my $dest (@ics) {
        my %grp_ids = map { $_ => 1 } $dest->get_grp_ids;
        ok( $grp_ids{$all_grp_id} && $grp_ids{$grp_id},
          "Check for both IDs" );
    }

    # Try deactivating one group membership.
    ok( my $mem = $grp->has_member({ obj => $ics[0] }), "Get member" );
    ok( $mem->deactivate->save, "Deactivate and save member" );

    # Now there should only be two using grp_id.
    ok( @ics = Bric::Biz::InputChannel->list({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id' again" );
    is( scalar @ics, 2, "Check for 2 input channels" );

    # story_instance_id and media_instance_id are actually tested by
    # Bric::Biz::Asset::Business::Story::DevTes and
    # Bric::Biz::Asset::Business::Media::DevTest.

    # Try active.
    ok( @ics = Bric::Biz::InputChannel->list({ active => 1 }),
        "Try active 1" );
    ok( $ics[0]->is_active, "Yes, is_active" );
    is( scalar @ics, 6, "Check for 6 input channels" );
    @ics = Bric::Biz::InputChannel->list({ active => 0 });
    ok(!@ics, "List active 0 has no results");
}

##############################################################################
# Test href().
sub test_href : Test(17) {
    # Start with the "name" attribute.
    ok(my $ics = Bric::Biz::InputChannel->href({ name => 'Default'}),
       "Href name 'Default'" );
    is(scalar keys %$ics, 1, "Check name number");
    is($ics->{1}->get_name, 'Default', "Check name 'Default'" );
    ok($ics = Bric::Biz::InputChannel->href({ name => 'de%'}),
       "Href name 'de%'" );
    is(scalar keys %$ics, 1, "Check wildcard name number");
    is($ics->{1}->get_name, 'Default', "Check wildcard name 'Default'" );
    $ics = Bric::Biz::InputChannel->href({ name => 'foo'});
    is(scalar keys %$ics, 0, "Href name 'foo' has no results");

    # Try the "description" attribute.
    ok($ics = Bric::Biz::InputChannel->href
       ({ description => 'Default input channel'}),
       "Href desc 'Default input channel'" );
    is(scalar keys %$ics, 1, "Check desc number");
    is($ics->{1}->get_description, 'Default input channel',
       "Check desc 'Default input channel'" );
    ok($ics = Bric::Biz::InputChannel->href({ description => '%channel'}),
       "Href desc '%channel'" );
    is(scalar keys %$ics, 1, "Check wildcard desc number");
    is($ics->{1}->get_description, 'Default input channel',
       "Check wildcard desc 'Default input channel'" );
    $ics = Bric::Biz::InputChannel->href({ description => 'foo'});
    is(scalar keys %$ics, 0, "List desc 'foo' has no results");

    # Try active.
    ok( $ics = Bric::Biz::InputChannel->href({ active => 1 }),
        "Try href active 1" );
    ok( $ics->{1}->is_active, "Yes, is_active" );
    $ics = Bric::Biz::InputChannel->href({ active => 0 });
    is(scalar keys %$ics, 0, "Href active 0 has no results");
}

##############################################################################
# Test class methods.
##############################################################################
# Test list_ids().
sub test_list_ids : Test(16) {
    # Start with the "name" attribute.
    ok(my @ids = Bric::Biz::InputChannel->list_ids({ name => 'Default'}),
       "List name IDs 'Default'" );
    is($#ids, 0, "Check name ID number");
    is( $ids[0], 1, "Check 'Default' ID number" );

    ok(@ids = Bric::Biz::InputChannel->list_ids({ name => 'def%'}),
       "List name ID 'def%'" );
    is($#ids, 0, "Check wildcard name ID number");
    is($ids[0], 1, "Check wildcard name ID" );
    @ids = Bric::Biz::InputChannel->list({ name => 'foo'});
    ok(!@ids, "List name 'foo' has no results");

    # Try the "description" attribute.
    ok(@ids = Bric::Biz::InputChannel->list_ids
       ({ description => 'Default input channel'}),
       "List ID desc 'Default input channel'" );
    is($#ids, 0, "Check desc ID number");
    is($ids[0], 1, "Check desc ID 1" );
    ok(@ids = Bric::Biz::InputChannel->list_ids({ description => '%channel'}),
       "List ID desc '%channel'" );
    is($#ids, 0, "Check wildcard ID desc number");
    is($ids[0], 1, "Check wildcard ID desc 1" );
    @ids = Bric::Biz::InputChannel->list_ids({ description => 'foo'});
    ok(!@ids, "List ID desc 'foo' has no results");

    # Try active.
    ok( @ids = Bric::Biz::InputChannel->list_ids({ active => 1 }),
        "Try list_ids active 1" );
    @ids = Bric::Biz::InputChannel->list_ids({ active => 0 });
    ok(!@ids, "List IDs active 0 has no results");
}


1;
__END__
