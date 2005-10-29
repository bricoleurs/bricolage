package Bric::Util::Grp::DevTest;

use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Util::Grp::Org;
use Bric::Biz::Org;
use Bric::Util::Grp::Person;
use Bric::Util::Grp::User;
use Bric::Util::Grp::AlertType;
use Bric::Util::Grp::Asset;
use Bric::Util::Grp::AssetType;
use Bric::Util::Grp::AssetVersion;
use Bric::Util::Grp::CategorySet;
use Bric::Util::Grp::ContribType;
use Bric::Util::Grp::Desk;
use Bric::Util::Grp::Dest;
use Bric::Util::Grp::Element;
use Bric::Util::Grp::ElementType;
use Bric::Util::Grp::Event;
use Bric::Util::Grp::Formatting;
use Bric::Util::Grp::Grp;
use Bric::Util::Grp::Job;
use Bric::Util::Grp::Keyword;
use Bric::Util::Grp::Media;
use Bric::Util::Grp::MediaType;
use Bric::Util::Grp::Org;
use Bric::Util::Grp::OutputChannel;
use Bric::Util::Grp::Person;
use Bric::Util::Grp::Pref;
use Bric::Util::Grp::Site;
use Bric::Util::Grp::Source;
use Bric::Util::Grp::Story;
use Bric::Util::Grp::Workflow;
use Bric::Biz::AssetType;

sub table { 'grp' }

my %grp = ( name => 'Testing',
            description => 'Description'
          );

##############################################################################
# Test the lookup() method and various accessors.
sub test_lookup : Test(20) {
    ok( my $grp = Bric::Util::Grp->lookup({ id => 1 }), "Lookup grp 1" );
    ok( UNIVERSAL::isa($grp, 'Bric::Util::Grp::Person'),
        "Check that it's a person group" );
    ok( UNIVERSAL::isa($grp, 'Bric::Util::Grp'), "Check that it's a  group" );
    is( $grp->get_id, 1, "Check 1's ID" );
    is( $grp->get_name, 'All Contributors', "Check 1's name" );
    is( $grp->get_description, 'All contributors in the system.',
        "Check 1's desc" );
    is( $grp->get_parent_id, 0, "Check 1's parent_id" );
    is( $grp->get_class_id, 9, "Check 1's class ID" );
    ok( ! $grp->is_secret, "Check 1's secret" );
    is( $grp->get_permanent, 1, "Check 1's permanance" );
    ok( my @pids = $grp->get_all_parent_ids, "Get 1's parent_ids" );
    is( scalar @pids, 1, "Check for 1 parent ID" );
    is( $pids[0], 0, "Check parent ID is root" );
    ok( $grp->is_active, "Check active" );

    # Check out a secret group.
    ok( $grp = Bric::Util::Grp->lookup({ id => 0 }), "Lookup grp 0" );
    ok( UNIVERSAL::isa($grp, 'Bric::Util::Grp'), "Check that it's a  group" );
    is( $grp->get_id, 0, "Check 0's ID" );
    is( $grp->get_name, 'Root Group', "Check 0's name" );
    ok( $grp->is_secret, "Check 0's secret" );
    is( $grp->get_permanent, 1, "Check 0's permanance" );
}

##############################################################################
# Test the list() method.
sub test_list : Test(40) {
    my $self = shift;
    ok( my @grps = Bric::Util::Grp->list({ name => 'All%' }),
        "get all All groups" );
    is( scalar @grps, 22, "Check number of All groups" );
    ok( @grps = Bric::Util::Grp->list({ name => 'All Users' }),
        "get All Users group" );
    is( scalar @grps, 1, "Check for one 'All Users' group" );
    is( $grps[0]->get_name, 'All Users', "Check 'All Users' name" );
    ok( UNIVERSAL::isa($grps[0], 'Bric::Util::Grp::User'),
        "Check 'All Users' class" );
    ok( @grps = Bric::Util::Grp->list({ permanent => 1, all => 1 }),
        "get all permanent groups" );
    is( scalar @grps, 30, "Check number of permanent groups" );
    ok( @grps = Bric::Util::Grp::Pref->list({ obj_id => 1,
                                              package => 'Bric::Util::Pref' }),
        "get all groups with pref 1 in them" );
    is( scalar @grps, 1, "Check for one 'Pref' group" );
    ok( UNIVERSAL::isa($grps[0], 'Bric::Util::Grp::Pref'),
    "Check 'All Preferences' class" );
    is( $grps[0]->get_name, 'All Preferences', "Check 'All Preferences' name" );

    # Create a new group group.
    ok( my $grpgrp = Bric::Util::Grp::Grp->new
        ({ name => 'Test GrpGrp' }),
        "Create group" );

    # Create some test records.
    for my $n (1..5) {
        my %args = %grp;
        # Make sure the directory name is unique.
        $args{name} .= $n if $n % 2;
        ok( my $grp = Bric::Util::Grp::ContribType->new(\%args),
            "Create $args{name}" );
        ok( $grp->save, "Save $args{name}" );
        # Save the ID for deleting.
        $self->add_del_ids([$grp->get_id]);
        $grpgrp->add_member({ obj => $grp }) if $n % 2;
    }

    ok( $grpgrp->save, "Save group group" );
    ok( my $grp_id = $grpgrp->get_id, "Get group group ID" );
    $self->add_del_ids([$grp_id]);

    # Try name.
    ok( @grps = Bric::Util::Grp->list({ name => $grp{name} }),
        "Look up name $grp{name}" );
    is( scalar @grps, 2, "Check for 2 groups" );

    # Try name + wildcard.
    ok( @grps = Bric::Util::Grp->list({ name => "$grp{name}%" }),
        "Look up name $grp{name}%" );
    is( scalar @grps, 5, "Check for 5 groups" );

    # Try grp_id.
    ok( @grps = Bric::Util::Grp->list({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id'" );
    is( scalar @grps, 3, "Check for 3 groups" );
    # Make sure we've got all the Group IDs we think we should have.
    my $all_grp_id = Bric::Util::Grp::INSTANCE_GROUP_ID;
    foreach my $grp (@grps) {
        my %grp_ids = map { $_ => 1 } $grp->get_grp_ids;
        ok( $grp_ids{$all_grp_id} && $grp_ids{$grp_id},
          "Check for both IDs" );
    }

    # Try deactivating one group membership.
    ok( my $mem = $grpgrp->has_member({ obj => $grps[0] }), "Get member" );
    ok( $mem->deactivate->save, "Deactivate and save member" );

    # Now there should only be two using grp_id.
    ok( @grps = Bric::Util::Grp->list({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id' again" );
    is( scalar @grps, 2, "Check for 2 groups" );

    # Try obj + all (so that it also returns the "All Groups" secret group.
    my $gid = $grps[0]->get_id;
    ok( @grps = Bric::Util::Grp::Grp->list({ obj => $grps[0], all => 1 }),
        "Look up for group ID $gid" );
    is( scalar @grps, 2, "Check for 2 groups" );
}

##############################################################################
# Test the list_ids() method.
sub test_list_ids : Test(10) {
    ok( my @grp_ids = Bric::Util::Grp->list_ids({ name => 'All%' }),
        "get all All groups" );
    is( scalar @grp_ids, 22, "Check number of All group IDs" );
    ok( @grp_ids = Bric::Util::Grp->list_ids({ name => 'All Users' }),
        "get All Users group ID" );
    is( scalar @grp_ids, 1, "Check for one 'All Users' group" );
    is( $grp_ids[0], 2, "Check 'All Users' ID" );
    ok( @grp_ids = Bric::Util::Grp->list_ids({ permanent => 1, all => 1 }),
        "get all permanent group IDs" );
    is( scalar @grp_ids, 30, "Check number of permanent group IDs" );
    ok( @grp_ids = Bric::Util::Grp::Pref->list_ids
        ({ obj_id => 1,
           package => 'Bric::Util::Pref' }),
        "get all group IDs with pref 1 in them" );
    is( scalar @grp_ids, 1, "Check for one 'Pref' group ID" );
    is( $grp_ids[0], 22, "Check 'All Preferences' ID" );
}

##############################################################################
# Check the href_grp_class_keys method.
sub test_href_class_keys : Test(6) {
    ok( my $subclasses = Bric::Util::Grp->href_grp_class_keys,
        "Get subclasses" ) or diag "Failed to get subclasses";
    is( $subclasses->{user_grp}, 'User Groups', "Check user_grp key" );
    ok( !$subclasses->{contrib_type}, "Secret contrib_type missing" );
    ok( $subclasses = Bric::Util::Grp->href_grp_class_keys(1),
        "Get all subclasses" );
    is( $subclasses->{user_grp}, 'User Groups', "Check user_grp key" );
    is( $subclasses->{contrib_type}, 'Contributor Types',
        "Check contrib_type key" );
}

##############################################################################
# Member tests.
##############################################################################
sub test_members : Test(36) {
    my $self = shift;
    # First, get a well-known group to play with.
    ok( my $grp = Bric::Util::Grp->lookup({ id => 22 }), "Get Prefs grp" );

    # Now test the get_members method.
    ok( my @mems = $grp->get_members, "Get pref members" );
    is( scalar @mems, 12, "Check number of pref mems" );
    ok( my ($mem) = (grep { $_->get_id == 401 } @mems), "Get tz member" );
    ok( UNIVERSAL::isa($mem, 'Bric::Util::Grp::Parts::Member'),
        "Check tz member class" );
    is( $mem->get_id, 401, "Check tz ID" );
    is( $mem->get_grp_id, 22, "Check tz member grp ID" );
    is( $mem->get_obj_id, 1, "Check tz member object ID" );

    # Try deleting a member.
    ok( $grp->delete_member($mem), "Delete Member" );
    ok( @mems = $grp->get_members, "Get pref members again" );
    is( scalar @mems, 11, "Check number of pref mems 2" );
    ok( ! (grep { $_->get_id == 401 } @mems), "Don't get tz member" );

    # Now add the member back.
    ok( $grp->add_member({ package => 'Bric::Util::Pref', id => 1 }),
        "Add the preference again" );
    ok( @mems = $grp->get_members, "Get pref members 3" );
    is( scalar @mems, 12, "Check number of pref mems 3" );

    # Play around with has_member().
    ok( $grp->has_member({ package => 'Bric::Util::Pref', id => 2 }),
        "Yes, has_member" );
    ok( ! $grp->has_member({ package => 'Bric::Util::Pref', id => -1 }),
        "No has_member" );

    # Now try an element group.
    my $story_elem_grp_id = 330;
    ok( $grp = Bric::Util::Grp->lookup({ id => $story_elem_grp_id }),
        "Look up story element group" );
    isa_ok($grp, "Bric::Util::Grp::AssetType");
    ok( @mems = $grp->get_members, "Get story element members" );
    is( scalar @mems, 2, "Check number of story element mems" );

    # Add a new element to the group.
    ok my $et = Bric::Biz::AssetType->new({
        name          => 'Test Element',
        key_name      => 'test_element',
        description   => 'Testing Element API',
        burner        => Bric::Biz::AssetType::BURNER_MASON,
        type__id      => 1,
        reference     => 0,
        primary_oc_id => 1,
    }), 'Create new element type';
    ok $et->save, 'Save it';
    ok my $et_id = $et->get_id, 'Get element type id';
    $self->add_del_ids($et_id, 'element');

    ok $grp->add_member({
        id      => $et_id,
        package => 'Bric::Biz::AssetType',
    }), 'Add test element to group';
    ok $grp->save, 'Save element group';

    # Look it up again and make sure all is well.
    ok( $grp = Bric::Util::Grp->lookup({ id => $story_elem_grp_id }),
        "Look up story element group again" );
    ok( @mems = $grp->get_members, "Get story element members" );
    is( scalar @mems, 3, "Check number of story element mems" );

    # Now remove the new element.
    ok( $grp = Bric::Util::Grp->lookup({ id => $story_elem_grp_id }),
        "Look up story element group again" );
    ok( ($mem) = (grep { $_->get_obj_id == $et_id  } @mems),
        "Get element type member" );
    ok( $grp->delete_member($mem), "Delete element type member" );
    diag "MEM: ", $mem->get_obj_id, $/;
    ok( $grp->save, "Save element group again" );

    # Look it up again and make sure all is well.
    ok( $grp = Bric::Util::Grp->lookup({ id => $story_elem_grp_id }),
        "Look up story element group yet again" );
    ok( @mems = $grp->get_members, "Get story element members" );
    is( scalar @mems, 2, "Check number of story element mems" );
}

##############################################################################
# Test the get_objects() method.
sub test_get_objects : Test(8) {
    my $self = shift;
    # First, get a well-known group to play with.
    ok( my $grp = Bric::Util::Grp->lookup({ id => 22 }), "Get Prefs grp" );

    # Now get the objects.
    ok( my @prefs = $grp->get_objects, "Get pref objects" );
    is( scalar @prefs, 12, "Check number of pref mems" );
    isa_ok( $prefs[0], 'Bric::Util::Pref' );

    # Try an element group, just for the heck of it.
    my $story_elem_grp_id = 330;
    ok( $grp = Bric::Util::Grp->lookup({ id => $story_elem_grp_id }),
        "Look up story element group" );
    ok( my @ats = $grp->get_objects, "Get story element objects" );
    is( scalar @ats, 2, "Check number of story elements" );
    isa_ok( $ats[0], 'Bric::Biz::AssetType');
}

##############################################################################
# Test get_member_ids. ID 22 is the All Preferences group.
sub test_mem_ids : Test(3) {
    ok( my @mem_ids = Bric::Util::Grp::Pref->get_member_ids(22),
        "Get all prefs member IDs" );
    ok( @mem_ids > 4, "Check number of member IDs" );
    ok( (grep { $_ == 2 } @mem_ids), "Check for individual member ID" );
}

##############################################################################
# Test the my_class class method.
sub test_my_class : Test(4) {
    ok( my $class = Bric::Util::Grp->my_class, "Get grp class" );
    is( $class->get_key_name, 'grp', "Check grp class key_name" );
    ok( $class = Bric::Util::Grp::Person->my_class, "Get Person class" );
    is( $class->get_key_name, 'contrib_type', "Check Person class key_name" );
}

##############################################################################
# Test the member_class class method.
sub test_member_class : Test(4) {
    ok( my $class = Bric::Util::Grp->member_class, "Get grp member class" );
    is( $class->get_key_name, 'bric', "Check grp member class key_name" );
    ok( $class = Bric::Util::Grp::Person->member_class,
        "Get Person member class" );
    is( $class->get_key_name, 'person', "Check Person member class key_name" );
}

##############################################################################
# Persistence tests. These tests assume that the test data is in the database.
# They will make changes to the database. You must have a fresh install of the
# database.
##############################################################################
sub test_persistence : Test(19) {
    my $self = shift;
    ok( my $o = Bric::Biz::Org->new({ name => 'IDG' }), "Create Org" );
    ok( $o->save, "Save Org" );
    $self->add_del_ids([$o->get_id], 'org');

    ok( my $grp = Bric::Util::Grp::Org->new({ name => 'Test Orgs'}),
        "Create org grp" );
    ok( $grp->add_members([{ obj => $o }]), "Add org" );
    ok( $grp->has_member({ obj => $o }), "Check with has_member" );
    ok( $grp->save, "Save org grp" );
    ok( my $gid = $grp->get_id, "Get org grp ID" );
    $self->add_del_ids([$gid]);
    ok( $grp = Bric::Util::Grp->lookup({ id => $gid }),
        "Lookup new org grp" );
    isa_ok($grp, 'Bric::Util::Grp::Org');
    is( $grp->get_name, 'Test Orgs', "Check Test Orgs name" );
    ok( my @mems = $grp->get_members, "Get test members" );
    is( scalar @mems, 1, "Check for one test member" );
    is( $mems[0]->get_obj_id, $o->get_id, "Check test member ID" );
    # Reload the group before removing the member.
    ok( $grp = Bric::Util::Grp->lookup({ id => $gid }),
        "Reload new org grp" );
    ok( $grp->delete_members([$o]),"Delete org member" );
    @mems = $grp->get_members;
    is( scalar @mems, 0, "Check for no members" );
    ok( $grp->save, "Save org grp again" );
    ok( $grp = Bric::Util::Grp->lookup({ id => $gid }),
        "Lookup org grp again" );
    @mems = $grp->get_members;
    is( scalar @mems, 0, "Check for no members again" );
}

1;
__END__
