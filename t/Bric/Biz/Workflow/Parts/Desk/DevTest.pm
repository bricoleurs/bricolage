package Bric::Biz::Workflow::Parts::Desk::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Bric::Biz::Workflow::Parts::Desk;
use Bric::Util::Grp::Desk;
use Bric::Biz::Asset::Business::Story::DevTest;
use Bric::Biz::Asset::Business::Media::DevTest;
use Bric::Biz::Asset::Template::DevTest;
use Test::More;

sub table { 'desk' };

my $edit_desk_id = 101;

my %desk = ( name => 'Test Desk',
             description => 'Testing Desk API',
           );


##############################################################################
# Test constructors.
##############################################################################
# Test the lookup() method.
sub test_lookup : Test(2) {
    my $self = shift;
    # Look up the ID in the delemabase.
    ok( my $desk = Bric::Biz::Workflow::Parts::Desk->lookup
        ({ id => $edit_desk_id }),
        "Look up edit desk" );
    is( $desk->get_id, $edit_desk_id, "Check that the ID is the same" );
}

##############################################################################
# Test the list() method.
sub test_list : Test(30) {
    my $self = shift;

    # Create a new workflow group.
    ok( my $grp = Bric::Util::Grp::Desk->new({ name => 'Test DeskGrp' }),
        "Create group" );

    # Create some test records.
    for my $n (1..5) {
        my %args = %desk;
        # Make sure the name is unique.
        $args{name} .= $n;
        $args{description} .= $n if $n % 2;
        ok( my $desk = Bric::Biz::Workflow::Parts::Desk->new(\%args),
            "Create $args{name}" );
        ok( $desk->save, "Save $args{name}" );
        # Save the ID for deleting.
        $self->add_del_ids($desk->get_id);
        $self->add_del_ids($desk->get_asset_grp, 'grp');
        $grp->add_member({ obj => $desk }) if $n % 2;
    }

    ok( $grp->save, "Save group" );
    ok( my $grp_id = $grp->get_id, "Get group ID" );
    $self->add_del_ids($grp_id, 'grp');

    # Try name + wildcard.
    ok( my @desks = Bric::Biz::Workflow::Parts::Desk->list
        ({ name => "$desk{name}%" }),
        "Look up name $desk{name}%" );
    is( scalar @desks, 5, "Check for 5 desks" );

    # Try description.
    ok( @desks = Bric::Biz::Workflow::Parts::Desk->list
        ({ description => "$desk{description}" }),
        "Look up description '$desk{description}'" );
    is( scalar @desks, 2, "Check for 2 desks" );

    # Try grp_id.
    ok( @desks = Bric::Biz::Workflow::Parts::Desk->list({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id'" );
    is( scalar @desks, 3, "Check for 3 desks" );
    # Make sure we've got all the Group IDs we think we should have.
    my $all_grp_id = Bric::Biz::Workflow::Parts::Desk::INSTANCE_GROUP_ID;
    foreach my $desk (@desks) {
        my %grp_ids = map { $_ => 1 } $desk->get_grp_ids;
        ok( $grp_ids{$all_grp_id} && $grp_ids{$grp_id},
          "Check for both IDs" );
    }

    # Try deactivating one group membership.
    ok( my $mem = $grp->has_member({ obj => $desks[0] }), "Get member" );
    ok( $mem->deactivate->save, "Deactivate and save member" );

    # Now there should only be two using grp_id.
    ok( @desks = Bric::Biz::Workflow::Parts::Desk->list({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id' again" );
    is( scalar @desks, 2, "Check for 2 desks" );

    # Try publish.
    ok( @desks = Bric::Biz::Workflow::Parts::Desk->list({ publish => 1 }),
        "Look up publish '1'" );
    # There should be 2 because of the default desks.
    is( scalar @desks, 2, "Check for 2 desks" );

    # Try active.
    ok( @desks = Bric::Biz::Workflow::Parts::Desk->list({ active => 1 }),
        "Look up active '1'" );
    # There shoudl be 12 because of the default "Story" workflow.
    is( scalar @desks, 12, "Check for 12 desks" );
}

##############################################################################
# Test the list_ids() method.
sub test_list_ids : Test(23) {
    my $self = shift;

    # Create a new workflow group.
    ok( my $grp = Bric::Util::Grp::Desk->new({ name => 'Test DeskGrp' }),
        "Create group" );

    # Create some test records.
    for my $n (1..5) {
        my %args = %desk;
        # Make sure the name is unique.
        $args{name} .= $n;
        $args{description} .= $n if $n % 2;
        ok( my $desk = Bric::Biz::Workflow::Parts::Desk->new(\%args),
            "Create $args{name}" );
        ok( $desk->save, "Save $args{name}" );
        # Save the ID for deleting.
        $self->add_del_ids($desk->get_id);
        $self->add_del_ids($desk->get_asset_grp, 'grp');
        $grp->add_member({ obj => $desk }) if $n % 2;
    }

    ok( $grp->save, "Save group" );
    ok( my $grp_id = $grp->get_id, "Get group ID" );
    $self->add_del_ids($grp_id, 'grp');

    # Try name + wildcard.
    ok( my @desk_ids = Bric::Biz::Workflow::Parts::Desk->list_ids
        ({ name => "$desk{name}%" }),
        "Look up name $desk{name}%" );
    is( scalar @desk_ids, 5, "Check for 5 desk IDs" );

    # Try description.
    ok( @desk_ids = Bric::Biz::Workflow::Parts::Desk->list_ids
        ({ description => "$desk{description}" }),
        "Look up description '$desk{description}'" );
    is( scalar @desk_ids, 2, "Check for 2 desk IDs" );

    # Try grp_id.
    ok( @desk_ids = Bric::Biz::Workflow::Parts::Desk->list_ids
        ({ grp_id => $grp_id }),
        "Look up grp_id $grp_id" );
    is( scalar @desk_ids, 3, "Check for 3 desk IDs" );

    # Try publish.
    ok( @desk_ids = Bric::Biz::Workflow::Parts::Desk->list_ids
        ({ publish => 1 }),
        "Look up publish '1'" );
    # There shoudl be 2 because of the default desks.
    is( scalar @desk_ids, 2, "Check for 2 desk IDs" );

    # Try active.
    ok( @desk_ids = Bric::Biz::Workflow::Parts::Desk->list_ids
        ({ active => 1 }),
        "Look up active '1'" );
    # There shoudl be 12 because of the default "Story" workflow.
    is( scalar @desk_ids, 12, "Check for 12 desk IDs" );
}

##############################################################################
# Test instance methods.
##############################################################################
# Test save()
sub test_save : Test(8) {
    my $test = shift;
    ok( my $desk = Bric::Biz::Workflow::Parts::Desk->lookup
        ({ id => $edit_desk_id }),
        "Look up story workflow" );
    ok( my $old_name = $desk->get_name, "Get its name" );
    my $new_name = $old_name . ' Foo';
    ok( $desk->set_name($new_name), "Set its name to '$new_name'" );
    ok( $desk->save, "Save it" );
    ok( Bric::Biz::Workflow::Parts::Desk->lookup({ id => $edit_desk_id }),
        "Look it up again" );
    is( $desk->get_name, $new_name, "Check name is '$new_name'" );
    # Restore the original name!
    ok( $desk->set_name($old_name), "Set its name back to '$old_name'" );
    ok( $desk->save, "Save it again" );
}

##############################################################################
# Make sure that we can put different assets on a desk and get them back.
sub test_assets : Test(39) {
    my $self = shift;
    is_deeply +Bric::Biz::Workflow::Parts::Desk->asset_counts, { },
        'Should have no assets on any desks';

    ok( my $desk = Bric::Biz::Workflow::Parts::Desk->lookup
        ({ id => $edit_desk_id }),
        "Look up story workflow" );

    # Create a story and put it on the desk.
    ok( my $s = Bric::Biz::Asset::Business::Story::DevTest->construct,
        "Create new story" );
    ok( $s->save, "Save story" );
    $self->add_del_ids($s->get_id, 'story');
    ok( $desk->accept({ asset => $s }), "Check story into desk" );
    ok( $desk->save, "Save desk" );

    # Check the assets.
    is_deeply +Bric::Biz::Workflow::Parts::Desk->asset_counts, { 101 => 1 },
        'Should now have one asset on desk 101';
    ok( my $assets = $desk->get_assets_href, "Get assets href" );
    is( scalar keys %$assets, 1, "Check for one type of asset" );
    is( scalar @{$assets->{story}}, 1, "Check for one story asset" );

    # Create another story and put it on the desk.
    ok( $s = Bric::Biz::Asset::Business::Story::DevTest->construct,
        "Create another new story" );
    ok( $s->save, "Save new story" );
    $self->add_del_ids($s->get_id, 'story');
    ok( $desk->accept({ asset => $s }), "Check new story into desk" );
    ok( $desk->save, "Save desk again" );
    ok( $s->save, "Save new story" );

    # Check the assets again.
    is_deeply +Bric::Biz::Workflow::Parts::Desk->asset_counts, { 101 => 2 },
        'Should now have two assets on desk 101';
    ok( $assets = $desk->get_assets_href, "Get assets href 2" );
    is( scalar keys %$assets, 1, "Check for one type of asset 2" );
    is( scalar @{$assets->{story}}, 2, "Check for two story assets" );

    # Create a media and put it on the desk.
    ok( my $m = Bric::Biz::Asset::Business::Media::DevTest->construct,
        "Create new media" );
    ok( $m->save, "Save media" );
    $self->add_del_ids($m->get_id, 'media');
    ok( $desk->accept({ asset => $m }), "Check media into desk" );
    ok( $desk->save, "Save desk" );

    # Check the assets again.
    is_deeply +Bric::Biz::Workflow::Parts::Desk->asset_counts, { 101 => 3 },
        'Should now have three assets on desk 101';
    ok( $assets = $desk->get_assets_href, "Get assets href again" );
    is( scalar keys %$assets, 2, "Check for two types of asset" );
    is( scalar @{$assets->{story}}, 2, "Check for two story assets" );
    is( scalar @{$assets->{media}}, 1, "Check for one media asset" );

    # Create another media and put it on the desk.
    ok( $m = Bric::Biz::Asset::Business::Media::DevTest->construct,
        "Create another new media" );
    ok( $m->save, "Save new media" );
    $self->add_del_ids($m->get_id, 'media');
    ok( $desk->accept({ asset => $m }), "Check new media into desk" );
    ok( $desk->save, "Save desk" );

    # Check the assets again.
    is_deeply +Bric::Biz::Workflow::Parts::Desk->asset_counts, { 101 => 4 },
        'Should now have four assets on desk 101';
    ok( $assets = $desk->get_assets_href, "Get assets href again" );
    is( scalar keys %$assets, 2, "Check for two types of asset" );
    is( scalar @{$assets->{story}}, 2, "Check for two story assets" );
    is( scalar @{$assets->{media}}, 2, "Check for two media assets" );
}

1;
__END__
