package Bric::Biz::Workflow::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Bric::Biz::Workflow;
use Bric::Util::Grp::Workflow;
use Test::More;

sub table { 'workflow' };

my $story_wf_id = 101;
my $edit_desk_id = 101;

my %wf = ( name        => 'Test Workflow',
           description => 'Testing Workflow API',
           start_desk  => $edit_desk_id,
           type        => Bric::Biz::Workflow::STORY_WORKFLOW,
           site_id     => 100,  #Use the default site_id
         );


##############################################################################
# Test constructors.
##############################################################################
# Test the lookup() method.
sub test_lookup : Test(4) {
    my $self = shift;
    # Look up the ID in the database.
    ok( my $wf = Bric::Biz::Workflow->lookup({ id => $story_wf_id }),
        "Look up story workflow" );
    is( $wf->get_id, $story_wf_id, "Check that the ID is the same" );

    ok( $wf = Bric::Biz::Workflow->lookup
        ({ site_id => 100, name => 'Story' }), "Look up story workflow" );
    is( $wf->get_id, $story_wf_id, "Check that the ID is the same" );
}

##############################################################################
# Test the list() method.
sub test_list : Test(32) {
    my $self = shift;

    # Create a new workflow group.
    ok( my $grp = Bric::Util::Grp::Workflow->new
        ({ name => 'Test WorkflowGrp' }),
        "Create group" );

    # Create some test records.
    for my $n (1..5) {
        my %args = %wf;
        # Make sure the name is unique.
        $args{name} .= $n;
        $args{description} .= $n if $n % 2;
        ok( my $wf = Bric::Biz::Workflow->new(\%args), "Create $args{name}" );
        ok( $wf->save, "Save $args{name}" );
        # Save the ID for deleting.
        $self->add_del_ids($wf->get_id);
        # Save the desk group IDs for deleting.
        $self->add_del_ids([$wf->get_all_desk_grp_id,
                            $wf->get_req_desk_grp_id], 'grp');
        $grp->add_member({ obj => $wf }) if $n % 2;
    }

    ok( $grp->save, "Save group" );
    ok( my $grp_id = $grp->get_id, "Get group ID" );
    $self->add_del_ids($grp_id, 'grp');

    # Try name + wildcard.
    ok( my @wfs = Bric::Biz::Workflow->list({ name => "$wf{name}%" }),
        "Look up name $wf{name}%" );
    is( scalar @wfs, 5, "Check for 5 workflows" );

    # Try description.
    ok( @wfs = Bric::Biz::Workflow->list
        ({ description => "$wf{description}" }),
        "Look up description '$wf{description}'" );
    is( scalar @wfs, 2, "Check for 2 workflows" );

    # Try grp_id.
    ok( @wfs = Bric::Biz::Workflow->list({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id'" );
    is( scalar @wfs, 3, "Check for 3 workflows" );
    # Make sure we've got all the Group IDs we think we should have.
    my $all_grp_id = Bric::Biz::Workflow::INSTANCE_GROUP_ID;
    foreach my $wf (@wfs) {
        my %grp_ids = map { $_ => 1 } $wf->get_grp_ids;
        ok( $grp_ids{$all_grp_id} && $grp_ids{$grp_id},
          "Check for both IDs" );
    }

    # Try deactivating one group membership.
    ok( my $mem = $grp->has_member({ obj => $wfs[0] }), "Get member" );
    ok( $mem->deactivate->save, "Deactivate and save member" );

    # Now there should only be two using grp_id.
    ok( @wfs = Bric::Biz::Workflow->list({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id' again" );
    is( scalar @wfs, 2, "Check for 2 workflows" );


    # Try type.
    ok( @wfs = Bric::Biz::Workflow->list({ type => "$wf{type}" }),
        "Look up type '$wf{type}'" );
    # There shoudl be 6 because of the default "Story" workflow.
    is( scalar @wfs, 6, "Check for 6 workflows" );

    # Try desk_id.
    ok( @wfs = Bric::Biz::Workflow->list({ desk_id => "$wf{start_desk}" }),
        "Look up desk_id '$wf{start_desk}'" );
    # There shoudl be 6 because of the default "Story" workflow.
    is( scalar @wfs, 6, "Check for 6 workflows" );

    # Try site_id
    ok( @wfs = Bric::Biz::Workflow->list({ site_id => 100 }),  #query default site
        "Look up site_id '100'");
    # There shoudl be 8 because of the default workflows
    is( scalar @wfs, 8, "Check for 8 workflows" );

}

##############################################################################
# Test the list_ids() method.
sub test_list_ids : Test(25) {
    my $self = shift;

    # Create a new workflow group.
    ok( my $grp = Bric::Util::Grp::Workflow->new
        ({ name => 'Test WorkflowGrp' }),
        "Create group" );

    # Create some test records.
    for my $n (1..5) {
        my %args = %wf;
        # Make sure the name is unique.
        $args{name} .= $n;
        $args{description} .= $n if $n % 2;
        ok( my $wf = Bric::Biz::Workflow->new(\%args), "Create $args{name}" );
        ok( $wf->save, "Save $args{name}" );
        # Save the ID for deleting.
        $self->add_del_ids($wf->get_id);
        # Save the desk group IDs for deleting.
        $self->add_del_ids([$wf->get_all_desk_grp_id,
                            $wf->get_req_desk_grp_id], 'grp');
        $grp->add_member({ obj => $wf }) if $n % 2;
    }

    ok( $grp->save, "Save group" );
    ok( my $grp_id = $grp->get_id, "Get group ID" );
    $self->add_del_ids($grp_id, 'grp');

    # Try name + wildcard.
    ok( my @wf_ids = Bric::Biz::Workflow->list_ids
        ({ name => "$wf{name}%" }),
        "Look up name $wf{name}%" );
    is( scalar @wf_ids, 5, "Check for 5 workflow IDs" );

    # Try description.
    ok( @wf_ids = Bric::Biz::Workflow->list_ids
        ({ description => "$wf{description}" }),
        "Look up description '$wf{description}'" );
    is( scalar @wf_ids, 2, "Check for 2 workflow IDs" );

    # Try grp_id.
    my $all_grp_id = Bric::Biz::Workflow::INSTANCE_GROUP_ID;
    ok( @wf_ids = Bric::Biz::Workflow->list_ids
        ({ grp_id => $grp_id }),
        "Look up grp_id $grp_id" );
    is( scalar @wf_ids, 3, "Check for 3 workflow IDs" );

    # Try type.
    ok( @wf_ids = Bric::Biz::Workflow->list_ids({ type => "$wf{type}" }),
        "Look up type '$wf{type}'" );
    # There shoudl be 6 because of the default "Story" workflow.
    is( scalar @wf_ids, 6, "Check for 6 workflow IDs" );

    # Try desk_id.
    ok( @wf_ids = Bric::Biz::Workflow->list_ids
        ({ desk_id => "$wf{start_desk}" }),
        "Look up desk_id '$wf{start_desk}'" );
    # There shoudl be 6 because of the default "Story" workflow.
    is( scalar @wf_ids, 6, "Check for 6 workflow IDs" );

    # Try site_id
    ok( @wf_ids = Bric::Biz::Workflow->list_ids
        ({ site_id => 100 }),  #query default site
        "Look up site_id '100'");
    # There shoudl be 8 because of the default workflows
    is( scalar @wf_ids, 8, "Check for 8 workflows" );

}

##############################################################################
# Test instance methods.
##############################################################################
# Test save()
sub test_save : Test(8) {
    my $test = shift;
    ok( my $wf = Bric::Biz::Workflow->lookup({ id => $story_wf_id }),
        "Look up story workflow" );
    ok( my $old_name = $wf->get_name, "Get its name" );
    my $new_name = $old_name . ' Foo';
    ok( $wf->set_name($new_name), "Set its name to '$new_name'" );
    ok( $wf->save, "Save it" );
    ok( Bric::Biz::Workflow->lookup({ id => $story_wf_id }),
        "Look it up again" );
    is( $wf->get_name, $new_name, "Check name is '$new_name'" );
    # Restore the original name!
    ok( $wf->set_name($old_name), "Set its name back to '$old_name'" );
    ok( $wf->save, "Save it again" );
}

1;
__END__
