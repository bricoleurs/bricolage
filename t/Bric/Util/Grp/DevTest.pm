package Bric::Util::Grp::DevTest;

use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More; # tests => 5;
use Bric::Util::Grp::Org;
use Bric::Biz::Org;

BEGIN {
    __PACKAGE__->test_class;
}

##############################################################################
# Persistence tests. These tests assume that the test data is in the database.
# They will make changes to the database. You must have a frech install of the
# database.
##############################################################################
sub test_persistence : Test(19) {
    ok( my $o = Bric::Biz::Org->new({ name => 'IDG' }), "Create Org" );
    ok( $o->save, "Save Org" );
    ok( my $grp = Bric::Util::Grp::Org->new({ name => 'Test Orgs'}),
        "Create org grp" );
    ok( $grp->add_members([{ obj => $o }]), "Add org" );

  TODO: {
        # Ideally, has_member() would work here, but it doesn't. The reason it
        # doesn't is becaus it doesn't check the member collection for the
        # member object because the collection hasn't been populated. So it
        # does a call to Member->list(), instead. Now, because the $grp object
        # wasn't saved after the call to add_members(), above, there's nothing
        # yet to find in the database.
        #
        # The upshot is that has_member() needs to be updated so that, even
        # when the collection hasn't been populated, it checks the member
        # collection for new members before it tries to query the
        # database. But this is a PITA, so I'm not doing it right now. So far,
        # a problem has been found with this in only one place (Desk.pm), and
        # it was easy to get around by simply adding a member object a second
        # time.
        local $TODO = 'Issue with has_member()';
        ok( $grp->has_member({ obj => $o }), "Check with has_member" );
    }

    ok( $grp->save, "Save org grp" );
    ok( my $gid = $grp->get_id, "Get org grp ID" );
    ok( $grp = Bric::Util::Grp->lookup({ id => $gid }),
        "Lookup new org grp" );
    ok( UNIVERSAL::isa($grp, 'Bric::Util::Grp::Org'),
        "Confirm org grp class" );
    is( $grp->get_name, 'Test Orgs', "Check Test Orgs name" );
    ok( my @mems = $grp->get_members, "Get test members" );
    ok( @mems == 1, "Check for one test member" );
    is( $mems[0]->get_obj_id, $o->get_id, "Check test member ID" );
    # Reload the group before removing the member.
    ok( $grp = Bric::Util::Grp->lookup({ id => $gid }),
        "Reload new org grp" );
    ok( $grp->delete_members([$o]),"Delete org member" );
    @mems = $grp->get_members;
    ok( @mems == 0, "Check for no members" );
    ok( $grp->save, "Save org grp again" );
    ok( $grp = Bric::Util::Grp->lookup({ id => $gid }),
        "Lookup org grp again" );
    @mems = $grp->get_members;
    ok( @mems == 0, "Check for no members again" );
}

1;
__END__
