package Bric::Util::Grp::Test;

use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

# Register this class for testing.
BEGIN { __PACKAGE__->test_class }

##############################################################################
# Test class loading.
##############################################################################
sub _load_test : Test(26) {
    # Load Grp and all of the subclasses. AssetVersion may not be used
    # anymore, but I leave it to another day to decide if that's so and take
    # it out if it is.
    use_ok('Bric::Util::Grp');
    use_ok('Bric::Util::Pref');
    for (qw(Person User AlertType Asset AssetType AssetVersion CategorySet
            ContribType Desk Dest Element ElementType Event Formatting Grp Job
            Media Org OutputChannel Person Pref Source Story Workflow)) {
        use_ok("Bric::Util::Grp::$_");
    }
}

##############################################################################
# Test the class methods.
##############################################################################
sub test_class_meths : Test(8) {
    is( Bric::Util::Grp->get_class_id, 6, "Class class ID is 6" );
    is( Bric::Util::Grp::Person->get_class_id, 9,
        "Person class class ID is 9" );
    ok( ! Bric::Util::Grp->get_supported_classes,
        "Check Grp supported classes." );
    is_deeply( Bric::Util::Grp::Person->get_supported_classes,
               { 'Bric::Biz::Person' => 'person',
                 'Bric::Biz::Person::User' => 'person' },
               "Check Person supported classes" );
    is( Bric::Util::Grp->get_secret, 1, "Check Grp secret" );
    is( Bric::Util::Grp::Source->get_secret, 0, "Check Source secret" );
    ok( !Bric::Util::Grp->get_object_class_id, "Check grp object_class_id" );
    is( Bric::Util::Grp::Person->get_object_class_id, 1,
        "Check Person object_class_id" );
}

##############################################################################
# Make sure that get_object_class_id and get_supported_classes always return a
# scalar value.
sub test_class_scalar_meths : Test(6) {
    ok( my @vals = Bric::Util::Grp->get_object_class_id,
        "Get Grp's obj class ID" );
    ok( @vals == 1, "Should be one value for obj class ID" );
    ok( ! defined $vals[0], "One value undef for obj class ID" );
    ok( @vals = Bric::Util::Grp->get_supported_classes,
        "Get Grp's supported classes" );
    ok( @vals == 1, "Should be one value for supported classes" );
    ok( ! defined $vals[0], "One value undef for supported classes" );
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
# Test get_member_ids. ID 22 is the All Preferences group.
sub test_mem_ids : Test(3) {
    ok( my @mem_ids = Bric::Util::Grp::Pref->get_member_ids(22),
        "Get all prefs member IDs" );
    ok( @mem_ids > 4, "Check number of member IDs" );
    ok( (grep { $_ == 2 } @mem_ids), "Check for individual member ID" );
}

##############################################################################
# Test my_meths.
sub test_my_meths : Test(6) {
    ok( my $meths = Bric::Util::Grp->my_meths, "Get my_meths" );
    is( ref $meths, 'HASH', "my_meths is a hash" );
    is( $meths->{name}{type}, 'short', "Check name type" );
    ok( $meths = Bric::Util::Grp->my_meths(1), "Get my_meths array ref" );
    is( ref $meths, 'ARRAY', "my_meths(1) is an array" );
    (is $meths->[0]->{name}, 'name', "Check first meth name" );
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
# Test the lookup() method and various accessors.
sub test_lookup : Test(14) {
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
  TODO: {
        local $TODO = 'Class vs instance naming conflict.';
        # There are a few class methods in Grp.pm that have the same names as
        # the instance methods generated by Bric.pm. This can cause conflicts,
        # and this Grp is an instance of that conflict. In reality, however,
        # it doesn't seem to matter much. Still, it'd be good to fix one of
        # these days.
        is( $grp->get_secret, 0, "Check 1's secret" );
    }
    is( $grp->get_permanent, 1, "Check 1's permanance" );
    ok( my @pids = $grp->get_all_parent_ids, "Get 1's parent_ids" );
    ok( @pids == 1, "Check for 1 parent ID" );
    is( $pids[0], 0, "Check parent ID is root" );
    ok( $grp->is_active, "Check active" );
}

##############################################################################
# Test the list() method.
sub test_list : Test(12) {
    ok( my @grps = Bric::Util::Grp->list({ name => 'All%' }),
        "get all All groups" );
    ok( @grps == 18, "Check number of All groups" );
    ok( @grps = Bric::Util::Grp->list({ name => 'All Users' }),
        "get All Users group" );
    ok( @grps == 1, "Check for one 'All Users' group" );
    is( $grps[0]->get_name, 'All Users', "Check 'All Users' name" );
    ok( UNIVERSAL::isa($grps[0], 'Bric::Util::Grp::User'),
        "Check 'All Users' class" );
    ok( @grps = Bric::Util::Grp->list({ permanent => 1 }),
        "get all permanent groups" );
    ok( @grps == 18, "Check number of permanent groups" );
    ok( @grps = Bric::Util::Grp::Pref->list({ obj_id => 1,
                                              package => 'Bric::Util::Pref' }),
        "get all groups with pref 1 in them" );
    ok( @grps == 1, "Check for one 'Pref' group" );
    ok( UNIVERSAL::isa($grps[0], 'Bric::Util::Grp::Pref'),
    "Check 'All Preferences' class" );
    is( $grps[0]->get_name, 'All Preferences', "Check 'All Preferences' name" );
}

##############################################################################
# Test the list_ids() method.
sub test_list_ids : Test(10) {
    ok( my @grp_ids = Bric::Util::Grp->list_ids({ name => 'All%' }),
        "get all All groups" );
    ok( @grp_ids == 18, "Check number of All group IDs" );
    ok( @grp_ids = Bric::Util::Grp->list_ids({ name => 'All Users' }),
        "get All Users group ID" );
    ok( @grp_ids == 1, "Check for one 'All Users' group" );
    is( $grp_ids[0], 2, "Check 'All Users' ID" );
    ok( @grp_ids = Bric::Util::Grp->list_ids({ permanent => 1 }),
        "get all permanent group IDs" );
    ok( @grp_ids == 18, "Check number of permanent group IDs" );
    ok( @grp_ids = Bric::Util::Grp::Pref->list_ids
        ({ obj_id => 1,
           package => 'Bric::Util::Pref' }),
        "get all group IDs with pref 1 in them" );
    ok( @grp_ids == 1, "Check for one 'Pref' group ID" );
    is( $grp_ids[0], 22, "Check 'All Preferences' ID" );
}

##############################################################################
# Member tests.
##############################################################################
sub test_members : Test(17) {
# First, get a well-known group to play with.
    ok( my $grp = Bric::Util::Grp->lookup({ id => 22 }), "Get Prefs grp" );

    # Now test the get_members method.
    ok( my @mems = $grp->get_members, "Get pref members" );
    ok( @mems == 9, "Check number of pref mems" );
    ok( my ($mem) = (grep { $_->get_id == 401 } @mems), "Get tz member" );
    ok( UNIVERSAL::isa($mem, 'Bric::Util::Grp::Parts::Member'),
        "Check tz member class" );
    is( $mem->get_id, 401, "Check tz ID" );
    is( $mem->get_grp_id, 22, "Check tz member grp ID" );
    is( $mem->get_obj_id, 1, "Check tz member object ID" );

    # Try deleting a member.
    ok( $grp->delete_member($mem), "Delete Member" );
    ok( @mems = $grp->get_members, "Get pref members again" );
    ok( @mems == 8, "Check number of pref mems 2" );
    ok( ! (grep { $_->get_id == 401 } @mems), "Don't get tz member" );

    # Now add the member back.
    ok( $grp->add_member({ package => 'Bric::Util::Pref', id => 1 }),
        "Add the preference again" );
    ok( @mems = $grp->get_members, "Get pref members 3" );
    ok( @mems == 9, "Check number of pref mems 3" );

    # Play around with has_member().
    ok( $grp->has_member({ package => 'Bric::Util::Pref', id => 2 }),
        "Yes, has_member" );
    ok( ! $grp->has_member({ package => 'Bric::Util::Pref', id => -1 }),
        "No has_member" );
}


1;
__END__
