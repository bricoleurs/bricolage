
package Bric::Cache::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Biz::Workflow;
use Bric::Biz::Site;
my $edit_desk_id = 101;
sub table { 'workflow' };
##############################################################################
# Test simple caching and debug flag
##############################################################################
sub test_const : Test(2) {

    {
        local $Bric::CACHE_DEBUG_MODE_RUNTIME = 1;
        local %Bric::DEBUG_CACHE;
        my $site = Bric::Biz::Site->lookup({id => 100});

        is($site, Bric::Biz::Site->lookup({id => 100}),
           "Check that the returned object is identical");
    }
    {
        my $site = Bric::Biz::Site->lookup({id => 100});

        isnt($site, Bric::Biz::Site->lookup({id => 100}),
           "Check that the returned object is not cached");
    }

}

##############################################################################
# Test unique caching
##############################################################################

sub test_unique : Test(7) {
    my $self = shift;
    local $Bric::CACHE_DEBUG_MODE_RUNTIME = 1;
    local %Bric::DEBUG_CACHE;

    my $site1 = Bric::Biz::Site->new( { name => "Dummy",
                                        domain_name => 'www.dummy1.com',
                                      });

    ok( $site1->save(), "Create first dummy site");
    my $site1_id = $site1->get_id;
    $self->add_del_ids($site1_id, 'site');

    my $wf1 = Bric::Biz::Workflow->new
      ({site_id     => 100,
        name        => 'test',
        description => 'test',
        start_desk  => $edit_desk_id,
        type        => Bric::Biz::Workflow::STORY_WORKFLOW,
       });
    ok($wf1->save(), "Save new workflow for default site");
    $self->add_del_ids($wf1->get_id);
    $self->add_del_ids([$wf1->get_all_desk_grp_id,
                        $wf1->get_req_desk_grp_id], 'grp');

    $wf1 = Bric::Biz::Workflow->lookup({'name' => 'test', site_id => 100});
    is($wf1->get_id,
       Bric::Biz::Workflow->lookup({'name' => 'test'})->get_id,
       "Test that the same workflow is returned");

    my $wf2 = Bric::Biz::Workflow->new
      ({site_id     => $site1_id,
        name        => 'test',
        description => 'test',
        start_desk  => $edit_desk_id,
        type        => Bric::Biz::Workflow::STORY_WORKFLOW,
       });
    ok($wf2->save(), "Save new workflow for site 1");
    $self->add_del_ids($wf2->get_id);
    $self->add_del_ids([$wf2->get_all_desk_grp_id,
                        $wf2->get_req_desk_grp_id], 'grp');

    $wf2 = Bric::Biz::Workflow->lookup({'name' => 'test',
                                       site_id => $site1_id});

    is($wf2->get_site_id, $site1_id, "Should get back the correct workflow" .
       "for this site");

    is($wf2->get_id,
       Bric::Biz::Workflow->lookup({'name' => 'test',
                                   site_id => $site1_id})->get_id,
       "Test that the same workflow is returned");

    isnt($wf1, $wf2, "The two workflows should not be the same object");
}

1;
