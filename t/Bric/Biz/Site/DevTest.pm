package Bric::Biz::Site::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Biz::Site;
use Bric::Util::Grp::Site;
use Bric::Biz::Person::User;
use Bric::Util::Grp::User;
use Bric::Util::Priv;
use Bric::Util::Priv::Parts::Const qw(:all);
use Bric::Util::Fault qw(isa_bric_exception);

my %init = ( name        => 'Testing',
             description => 'Description',
             domain_name => 'example.org',
           );

sub table { 'site' }

##############################################################################
# Setup methods.
##############################################################################
# Setup some sites to play with.
sub setup_sites : Test(setup => 31) {
    my $self = shift;
    # Create a new site group.
    ok( my $grp = Bric::Util::Grp::Site->new({ name => 'Test SiteGrp' }),
        "Create group" );

    # Retrieve the "All Users" group.
    my $ug_id = Bric::Biz::Person::User->INSTANCE_GROUP_ID;
    ok( my $usr_grp = Bric::Util::Grp::User->lookup({ id => $ug_id }),
        "Look up All Users" );

    # Create a new user group.
    ok( my $deny_grp = Bric::Util::Grp::User->new({ name => 'Deny Users' }),
        "Create deny user group" );
    ok( $deny_grp->add_member({ id      => $self->user_id,
                                package => 'Bric::Biz::Person::User' }),
        "Add admin user to deny group" );
    ok( $deny_grp->save, "Save deny group" );
    $self->add_del_ids($deny_grp->get_id, 'grp');

    # Create some test records.
    my @sites;
    for my $n (1..5) {
        my %args = %init;
        my $name = $args{name} .= " $n";
        $args{domain_name} = "ww$n.$args{domain_name}";
        $args{description} .= $n if $n % 2;
        ok( my $site = Bric::Biz::Site->new(\%args), "Create '$name'" );
        ok( $site->save, "Save '$name'" );
        # Save the ID for deleting (delete the group, too!).
        my $id = $site->get_id;
        $self->add_del_ids($id);
        $self->add_del_ids($id, 'grp');
        # Create the permission and schedule it for deletion.
        ok( my $priv = Bric::Util::Priv->new({ usr_grp => $usr_grp,
                                               obj_grp => $site->get_grp,
                                               value   => CREATE }),
            "Create CREATE priv" );
        ok( $priv->save, "Save priv" );
        $self->add_del_ids($priv->get_id, 'grp_priv');


        if ($n % 2) {
            $grp->add_member({ obj => $site }) if $n % 2;
        } else {
            # Create a DENY permission. It should override the CREATE
            # permission for the two sites it's created for.
            ok( my $priv = Bric::Util::Priv->new({ usr_grp => $deny_grp,
                                                   obj_grp => $site->get_grp,
                                                   value   => DENY }),
                "Create DENY priv" );
            ok( $priv->save, "Save priv" );
            $self->add_del_ids($priv->get_id, 'grp_priv');
        }

        # Save the new site.
        push @sites, $site;
    }

    # Save the groups.
    ok( $grp->save, "Save group" );
    ok( my $grp_id = $grp->get_id, "Get group ID" );
    $self->add_del_ids($grp_id, 'grp');
    $self->{test_sites} = \@sites;
    $self->{test_grp} = $grp;
}

##############################################################################
# Test constructors.
##############################################################################
# Test new().
sub test_new : Test(0) {
    my $self = shift;
    # All handled by setup_sites().
}

##############################################################################
# Test lookup().
sub test_lookup : Test(20) {
    my $self = shift;

    ok( my $sid = $self->{test_sites}[0]->get_id, "Get site ID" );

    # Try ID.
    ok( my $site = Bric::Biz::Site->lookup({ id => $sid }),
        "Look up ID '$sid'" );
    isa_ok($site, 'Bric::Biz::Site');
    is( $site->get_id, $sid, "Site ID is '$sid'" );

    # Try a bogus ID.
    ok( ! Bric::Biz::Site->lookup({ id => -1 }), "Look up bogus ID" );

    # Make sure we can grab the default site!
    ok( $site = Bric::Biz::Site->lookup({ id => 100 }),
        "Look up default site" );
    isa_ok($site, 'Bric::Biz::Site');
    is( $site->get_id, 100, "Check default site ID is '100'" );

    # Try name.
    my $name = "$init{name} 1";
    ok( $site = Bric::Biz::Site->lookup({ name => $name }),
        "Look up '$name'" );
    isa_ok($site, 'Bric::Biz::Site');
    is( $site->get_name, "$name", "Check name is '$name'" );

    # Try a bogus name.
    ok( ! Bric::Biz::Site->lookup({ name => -1 }), "Look up bogus name" );

    # Try too many sites by name.
    eval { Bric::Biz::Site->lookup({ name => "$init{name}%" }) };
    ok( my $err = $@, "Grab exception" );
    ok( isa_bric_exception($err, 'DA'), "Is a DA exception" );

    # Try domain_name.
    my $dn = "ww1.$init{domain_name}";
    ok( $site = Bric::Biz::Site->lookup({ domain_name => $dn }),
        "Look up '$dn'" );
    isa_ok($site, 'Bric::Biz::Site');
    is( $site->get_domain_name, $dn, "Check domain_name is '$dn'" );

    # Try a bogus domain_name.
    ok( ! Bric::Biz::Site->lookup({ domain_name => -1 }),
        "Look up bogus domain name" );

    # Try too many sites by domain_name.
    eval { Bric::Biz::Site->lookup({ domain_name => "ww%" }) };
    ok( $err = $@, "Grab exception" );
    ok( isa_bric_exception($err, 'DA'), "Is a DA exception" );

}

##############################################################################
# Test list().
sub test_list : Test(28) {
    my $self = shift;

    # Try name.
    my @sites = Bric::Biz::Site->list({ name => $init{name} });
    is( scalar @sites, 0, "Check for 0 sites" );

    # Try name + wildcard.
    ok( @sites = Bric::Biz::Site->list({ name => "$init{name}%" }),
        "List name '$init{name}%'" );
    is( scalar @sites, 5, "Check for 5 sites" );

    # Try a bogus name.
    ok( ! Bric::Biz::Site->list({ name => -1 }), "List bogus name" );

    # Try description.
    ok( @sites = Bric::Biz::Site->list({ description => $init{description} }),
        "List description '$init{description}'" );

    is( scalar @sites, 2, "Check for 2 sites" );

    # Try description + wildcard.
    ok( @sites = Bric::Biz::Site->list
        ({ description => "$init{description}%" }),
        "List description '$init{description}%'" );
    is( scalar @sites, 5, "Check for 5 sites" );

    # Try a bogus description.
    ok( ! Bric::Biz::Site->list({ description => -1 }),
        "List bogus description" );

    # Try domain_name.
    @sites = Bric::Biz::Site->list({ domain_name => $init{domain_name} });
    is( scalar @sites, 0, "Check for 0 sites" );

    # Try domain_name + wildcard.
    ok( @sites = Bric::Biz::Site->list({ domain_name => "ww%" }),
        "List domain_name 'ww%'" );
    # There are 6 because the default site is 'www.example.com'.
    is( scalar @sites, 6, "Check for 6 sites" );

    # Try a bogus domain_name.
    ok( ! Bric::Biz::Site->list({ domain_name => -1 }),
        "List bogus domain name" );

    # Try grp_id.
    my $grp = $self->{test_grp};
    my $grp_id = $grp->get_id;
    ok( @sites = Bric::Biz::Site->list({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id'" );
    is( scalar @sites, 3, "Check for 3 sites" );
    # Make sure we've got all the Group IDs we think we should have.
    my $all_grp_id = Bric::Biz::Site::INSTANCE_GROUP_ID;
    foreach my $site (@sites) {
        my %grp_ids = map { $_ => 1 } @{ $site->get_grp_ids };
        ok( $grp_ids{$all_grp_id} && $grp_ids{$grp_id},
          "Check for both IDs" );
    }

    # Try deactivating one group membership.
    ok( my $mem = $grp->has_member({ obj => $sites[0] }), "Get member" );
    ok( $mem->deactivate->save, "Deactivate and save member" );

    # Now there should only be two using grp_id.
    ok( @sites = Bric::Biz::Site->list({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id' again" );
    is( scalar @sites, 2, "Check for 2 sites" );

    # Try active.
    ok( @sites = Bric::Biz::Site->list({ active => 1}), "List active => 1" );
    is( scalar @sites, 6, "Check for 6 sites" );

    # Deactivate one and make sure it doesn't come back.
    ok( $self->{test_sites}[0]->deactivate->save,
        "Deactivate and save a site" );
    ok( @sites = Bric::Biz::Site->list({ active => 1}),
        "List active => 1 again" );
    is( scalar @sites, 5, "Check for 5 sites" );
}

##############################################################################
# Test class methods.
##############################################################################
# Test list().
sub test_list_ids : Test(25) {
    my $self = shift;

    # Try name.
    my @site_ids = Bric::Biz::Site->list_ids({ name => $init{name} });
    is( scalar @site_ids, 0, "Check for 0 site IDs" );

    # Try name + wildcard.
    ok( @site_ids = Bric::Biz::Site->list_ids({ name => "$init{name}%" }),
        "List IDs name '$init{name}%'" );
    is( scalar @site_ids, 5, "Check for 5 site IDs" );

    # Try a bogus name.
    ok( ! Bric::Biz::Site->list_ids({ name => -1 }), "List IDs bogus name" );

    # Try description.
    ok( @site_ids = Bric::Biz::Site->list_ids
        ({ description => $init{description} }),
        "List IDs description '$init{description}'" );

    is( scalar @site_ids, 2, "Check for 2 site IDs" );

    # Try description + wildcard.
    ok( @site_ids = Bric::Biz::Site->list_ids
        ({ description => "$init{description}%" }),
        "List IDs description '$init{description}%'" );
    is( scalar @site_ids, 5, "Check for 5 site IDs" );

    # Try a bogus description.
    ok( ! Bric::Biz::Site->list_ids({ description => -1 }),
        "List IDs bogus description" );

    # Try domain_name.
    @site_ids = Bric::Biz::Site->list_ids({ domain_name => $init{domain_name} });
    is( scalar @site_ids, 0, "Check for 0 site IDs" );

    # Try domain_name + wildcard.
    ok( @site_ids = Bric::Biz::Site->list_ids({ domain_name => "ww%" }),
        "List IDs domain_name 'ww%'" );
    # There are 6 because the default site is 'www.example.com'.
    is( scalar @site_ids, 6, "Check for 6 site IDs" );

    # Try a bogus domain_name.
    ok( ! Bric::Biz::Site->list_ids({ domain_name => -1 }),
        "List IDs bogus domain name" );

    # Try grp_id.
    my $grp = $self->{test_grp};
    my $grp_id = $grp->get_id;
    ok( @site_ids = Bric::Biz::Site->list_ids({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id'" );
    is( scalar @site_ids, 3, "Check for 3 site IDs" );

    # Try deactivating one group membership.
    ok( my $mem = $grp->has_member({ obj => $self->{test_sites}[0] }),
        "Get member" );
    ok( $mem->deactivate->save, "Deactivate and save member" );

    # Now there should only be two using grp_id.
    ok( @site_ids = Bric::Biz::Site->list_ids({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id' again" );
    is( scalar @site_ids, 2, "Check for 2 site IDs" );

    # Try active.
    ok( @site_ids = Bric::Biz::Site->list_ids({ active => 1}), "List IDs active => 1" );
    is( scalar @site_ids, 6, "Check for 6 site IDs" );

    # Deactivate one and make sure it doesn't come back.
    ok( $self->{test_sites}[0]->deactivate->save,
        "Deactivate and save a site" );
    ok( @site_ids = Bric::Biz::Site->list_ids({ active => 1}),
        "List IDs active => 1 again" );
    is( scalar @site_ids, 5, "Check for 5 site IDs" );
}

##############################################################################
# Test instance methods.
##############################################################################
# Test save() method (and the instance methods, while we're at it!).
sub test_save : Test(36) {
    my $self = shift;
    my $site = $self->{test_sites}[0];
    my ($name, $dn, $desc) = ('Save', 'foo.org', 'Hey!');
    ok( $site->set_name($name), "Change name" );
    is( $site->get_name, $name, "Check name" );
    ok( $site->set_domain_name($dn), "Change domain name" );
    is( $site->get_domain_name, $dn, "Check domain name" );
    ok( $site->set_description($desc), "Change description" );
    is( $site->get_description, $desc, "Check description" );
    ok( $site->is_active, "Check is active" );
    is( $site->get_grp->get_id, $site->get_id, "Check group ID is ID" );
    ok( my $grp_ids = $site->get_grp_ids, "Get group IDs" );
    isa_ok( $grp_ids, 'ARRAY', "Check group IDs are in an array" );
    # There could be other group IDs, but we can't know what they are now.
    ok( scalar @$grp_ids >= 2, "Check for at least two group IDs" );
    ok( $site->save, "Save site" );

    # Look it up in the database and verify the values.
    ok( $site = $site->lookup({ id => $site->get_id }), "Look up site" );
    is( $site->get_name, $name, "Check name" );
    is( $site->get_domain_name, $dn, "Check domain name" );
    is( $site->get_description, $desc, "Check description" );
    ok( $site->is_active, "Check is active" );
    is( $site->get_grp->get_id, $site->get_id, "Check group ID is ID" );
    ok( $grp_ids = $site->get_grp_ids, "Get group IDs" );
    isa_ok( $grp_ids, 'ARRAY', "Check group IDs are in an array" );
    ok( scalar @$grp_ids >= 2, "Check for at least two group IDs" );

    # Do it again, this time also deactivating.
    ($name, $dn, $desc) = ('Ick', 'foo.net', 'Oooo!');
    ok( $site->set_name($name), "Change name" );
    is( $site->get_name, $name, "Check name" );
    ok( $site->set_domain_name($dn), "Change domain name" );
    is( $site->get_domain_name, $dn, "Check domain name" );
    ok( $site->set_description($desc), "Change description" );
    is( $site->get_description, $desc, "Check description" );
    ok( $site->deactivate, "Deactivate site" );
    ok( $site->save, "Save site" );

    # Look it up in the database and verify the values again.
    ok( $site = $site->lookup({ id => $site->get_id }), "Look up site" );
    is( $site->get_name, $name, "Check name" );
    is( $site->get_domain_name, $dn, "Check domain name" );
    is( $site->get_description, $desc, "Check description" );
    ok( ! $site->is_active, "Check is not active" );
    is( $site->get_grp->get_id, $site->get_id, "Check group ID is ID" );
    ok( eq_set( scalar $site->get_grp_ids, $grp_ids), "Check group IDs" );
}


1;
__END__
