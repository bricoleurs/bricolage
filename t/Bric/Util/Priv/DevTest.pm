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
    is( scalar @privs, 5, "Check for 5 privs" );

    # Try value.
    ok( @privs = Bric::Util::Priv->list({ value => CREATE }),
        "Look up by value 'CREATE'" );
    is( scalar @privs, 22, "Check for 22 privs" );
    ok( @privs = Bric::Util::Priv->list({ value => READ }),
        "Look up by value 'READ'" );
    is( scalar @privs, 12, "Check for 12 privs" );
}

##############################################################################
# Test Class Methods.
##############################################################################
# Test get_acl.
sub test_get_acl : Test(3) {
    my $self = shift;
    my $test_acl = { 22 => 4,
                     1  => 4,
#                     'mtime' => '2003-02-22 02:43:35',
                     23 => 1,
                     26 => 4,
                     29 => 1
                   };

    my $uid = $self->user_id; # Admin user is in "All Users" group.
    ok( my $acl = Bric::Util::Priv->get_acl($uid), "Get ACL for UID '$uid'" );
    ok( local_date(delete $acl->{mtime}), "Check for parsable mtime" );
    is_deeply($acl, $test_acl, "Compare ACLs" );
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

1;
__END__
