package Bric::Util::Priv::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Util::Priv;
use Bric::Util::Priv::Parts::Const qw(:all);
use Bric::Biz::Person::User;
use Bric::Biz::Category;
use Bric::Biz::OutputChannel;
use Bric::Biz::Person;
use Bric::Dist::ServerType;
use Bric::Util::Pref;
use Bric::Util::Grp;
use Bric::Util::Time qw(db_date local_date);
use Bric::Config qw(:time);

sub table { 'grp_priv' }

my $usr_grp = Bric::Util::Grp->lookup
  ({ id => Bric::Biz::Person::User->INSTANCE_GROUP_ID });

my @grps =
  ( Bric::Util::Grp->lookup({ id => Bric::Biz::Category->INSTANCE_GROUP_ID }),
    Bric::Util::Grp->lookup({ id => Bric::Biz::OutputChannel->INSTANCE_GROUP_ID }),
    Bric::Util::Grp->lookup({ id => Bric::Biz::Person->INSTANCE_GROUP_ID }),
    Bric::Util::Grp->lookup({ id => Bric::Dist::ServerType->INSTANCE_GROUP_ID }),
    Bric::Util::Grp->lookup({ id => Bric::Util::Pref->INSTANCE_GROUP_ID }),
  );

my %test_vals = ( usr_grp => $usr_grp,
                  obj_grp => $grps[0],
                  value   => CREATE
                );

##############################################################################
# Setup methods. These will be run before every test, even if their data might
# not be used for every test.
##############################################################################

sub load_privs : Test(setup => 10) {
    my $self = shift;
    my @privs;
    # Create some test records.
    for my $n (0..4) {
        my %args = %test_vals;
        # Make sure that the object group is different.
        $args{obj_grp} = $grps[$n];
        $args{value} = READ if $n % 2;
        my $name = $grps[$n]->get_name;

        ok( my $priv = Bric::Util::Priv->new(\%args), "Create '$name' priv" );
        ok( $priv->save, "Save $name priv" );

        # Save the priv and schedule it for deletion.
        $self->add_del_ids($priv->get_id);
        push @privs, $priv;
    }
    $self->{test_privs} = \@privs;
}

##############################################################################
# Test constructors.
##############################################################################
# Test the lookup() method.
sub test_lookup : Test(8) {
    my $self = shift;

    # Look up the first group.
    ok( my $priv_id = $self->{test_privs}[0]->get_id, "Get priv ID" );
    ok( my $priv = Bric::Util::Priv->lookup({ id => $priv_id}),
        "Look up priv '$priv_id;" );
    isa_ok($priv, 'Bric::Util::Priv');
    my $usr_grp_id = $test_vals{usr_grp}->get_id;
    is( $priv->get_usr_grp_id, $usr_grp_id,
        "Check usr_grp_id = '$usr_grp_id'" );
    my $obj_grp_id = $test_vals{obj_grp}->get_id;
    is( $priv->get_obj_grp_id, $obj_grp_id,
        "Check obj_grp_id = '$obj_grp_id'" );
    is( $priv->get_value, $test_vals{value},
        "Check value = '$test_vals{value}'" );

    # Make sure we have a parsable time.
    ok( my $mtime = $priv->get_mtime(ISO_8601_FORMAT), "Get mtime" );
    ok( db_date($mtime), "Check mtime" );
}

##############################################################################
# Test list().
sub test_list : Test(8) {
    my $self = shift;

    # Try usr_grp_id.
    ok( my @privs = Bric::Util::Priv->list({ usr_grp_id => $usr_grp->get_id }),
        "Look up by usr_grp_id" );
    is( scalar @privs, 5, "Check for 5 privs" );

    # Try obj_grp_id.
    my $cat_grp_id = $grps[0]->get_id;
    ok( @privs = Bric::Util::Priv->list({ obj_grp_id => $cat_grp_id }),
        "Look up by obj_grp_id '$cat_grp_id'" );
    is( scalar @privs, 5, "Check for 5 priv" );

    # Try value.
    ok( @privs = Bric::Util::Priv->list({ value => CREATE }),
        "Look up by value 'CREATE'" );
    is( scalar @privs, 23, "Check for 23 privs" );
    ok( @privs = Bric::Util::Priv->list({ value => READ }),
        "Look up by value 'READ'" );
    is( scalar @privs, 8, "Check for 8 privs" );
}

##############################################################################
# Test Class Methods.
##############################################################################
# Test get_acl.
sub test_get_acl : Test(3) {
    my $self = shift;
    my $test_acl = { 22 => 3,
                     1  => 3,
#                     'mtime' => '2003-02-22 02:43:35',
                     23 => 1,
                     26 => 3,
                     29 => 1
                   };

    my $uid = $self->user_id; # Admin user is in "All Users" group.
    ok( my $acl = Bric::Util::Priv->get_acl($uid), "Get ACL for UID '$uid'" );
    ok( local_date(delete $acl->{mtime}), "Check for parsable mtime" );
    ok( eq_hash($acl, $test_acl), "Compare ACLs" );
}

##############################################################################
# Test get_acl_mtime.
sub test_get_acl_mtime : Test(3) {
    my $self = shift;
    my $uid = $self->user_id; # Admin user is in "All Users" group.
    ok( my $acl = Bric::Util::Priv->get_acl($uid), "Get ACL for UID '$uid'" );
    ok( my $mtime = Bric::Util::Priv->get_acl_mtime($uid),
        "Get mtime for UID '$uid'" );
    is( $mtime, $acl->{mtime}, "Check mtime" );
}

##############################################################################
# Test inactive groups.
sub test_inactive_groups : Test(37) {
    my $self = shift;
    my $uid = $self->user_id;

    # Create a new user group and add a user to it.
    ok( my $ug = Bric::Util::Grp::User->new({ name => 'FooUser' }),
        "Create new user group");
    ok( $ug->add_member({ package => 'Bric::Biz::Person::User',
                          id => $uid }),
        "Add user to group" );
    ok( $ug->save, "Save new user group" );
    ok( my $ugid = $ug->get_id, "Get user group ID" );
    $self->add_del_ids($ugid, 'grp');
    ok( $ug = $ug->lookup({ id => $ugid }), "Grab user group from database" );

    # Create a new MediaType group and add a media type to it.
    ok( my $mg = Bric::Util::Grp::MediaType->new({ name => 'FooMT'}),
        "Create new MT group" );
    ok( $mg->save, "Save new MT group" );
    ok( my $mgid = $mg->get_id, "Get MT group ID" );
    $self->add_del_ids($mgid, 'grp');
    ok( $mg = $mg->lookup({ id => $mgid }), "Grab MT group from database" );

    # Grant the new user group permission to the new MT group.
    ok( my $priv = Bric::Util::Priv->new({ usr_grp => $ug,
                                           obj_grp => $mg,
                                           value => CREATE}),
        "Create permission for new user group" );
    ok( $priv->save, "Save new permission" );
    $self->add_del_ids($priv->get_id);

    # Make sure that the user has the new group in its ACL.
    ok( my $acl = Bric::Util::Priv->get_acl($uid), "Get ACL for UID '$uid'" );
    is( $acl->{$mgid}, 3, "Check for MT group in ACL" );

    # Now, remove the user from the user group.
    ok( $ug->delete_member({ package => 'Bric::Biz::Person::User',
                             id => $uid }),
        "Delete user from user group" );
    ok( $ug->save, "Save user group again" );

    # So the MT group should no longer be in the ACL.
    ok( $acl = Bric::Util::Priv->get_acl($uid), "Get ACL for UID '$uid'" );
    is( $acl->{$mgid}, undef, "Check for no MT group in ACL" );

     # Add the user back to the user group.
    ok( $ug->add_member({ package => 'Bric::Biz::Person::User',
                          id => $uid }),
        "Add user back to group" );
    ok( $ug->save, "Save user group" );

    # Make sure that the user again has the new group in its ACL.
    ok( $acl = Bric::Util::Priv->get_acl($uid), "Get ACL for UID '$uid'" );
    is( $acl->{$mgid}, 3, "Check for MT group in ACL again" );

    # Now, deactivate the new user group!
    ok( $ug->deactivate, "Deactivate user group" );
    ok( $ug->save, "Save deactivated user group" );

    # So the MT group should gone from the ACL again.
    ok( $acl = Bric::Util::Priv->get_acl($uid), "Get ACL for UID '$uid'" );
    is( $acl->{$mgid}, undef, "Check for no MT group in ACL again" );

    # Reactivate the user group.
    ok( $ug->activate, "Re-activate user group" );
    ok( $ug->save, "Save re-activated user group" );

    # So the MT group should back in the ACL again.
    ok( $acl = Bric::Util::Priv->get_acl($uid), "Get ACL for UID '$uid'" );
    is( $acl->{$mgid}, 3, "Check for MT group in ACL again" );

    # Now deactivate the MT group.
    ok( $mg->deactivate, "Deactivate MT group" );
    ok( $mg->save, "Save deactivated MT group" );

    # So the MT group should gone from the ACL again.
    ok( $acl = Bric::Util::Priv->get_acl($uid), "Get ACL for UID '$uid'" );
    is( $acl->{$mgid}, undef, "Bye-bye MT group" );

    # Re-activate the MT group.
    ok( $mg->activate, "Re-activate MT group" );
    ok( $mg->save, "Save re-activated MT group" );

    # So the MT group should back in the ACL again.
    ok( $acl = Bric::Util::Priv->get_acl($uid), "Get ACL for UID '$uid'" );
    is( $acl->{$mgid}, 3, "Back and better than ever!" );
}

1;
__END__
