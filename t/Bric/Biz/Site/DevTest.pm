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
sub setup_sites : Test(setup => 13) {
    my $self = shift;
    # Create a new site group.
    ok( my $grp = Bric::Util::Grp::Site->new({ name => 'Test SiteGrp' }),
        "Create group" );

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
        $grp->add_member({ obj => $site }) if $n % 2;

        # Cache the new site.
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
    ok( isa_bric_exception($err, 'Exception::DA'),
        "Is a Exception::DA exception" );

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
    ok( isa_bric_exception($err, 'Exception::DA'),
        "Is a Exception::DA exception" );

}

##############################################################################
# Test list().
sub test_list : Test(27) {
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
# Test href().
sub test_href : Test(25) {
    my $self = shift;

    # Try name.
    my $sites = Bric::Biz::Site->href({ name => $init{name} });
    is( scalar keys %$sites, 0, "Check for 0 sites" );

    # Try name + wildcard.
    ok( $sites = Bric::Biz::Site->href({ name => "$init{name}%" }),
        "List name '$init{name}%'" );
    is( scalar keys %$sites, 5, "Check for 5 sites" );

    # Check the hash keys.
    while (my ($id, $site) = each %$sites) {
        is($id, $site->get_id, "Check site ID '$id'" );
    }

    # Try a bogus name.
    is_deeply(Bric::Biz::Site->href({ name => -1 }) , {}, "List bogus name" );
    # Try description.
    ok( $sites = Bric::Biz::Site->href({ description => $init{description} }),
        "List description '$init{description}'" );

    is( scalar keys %$sites, 2, "Check for 2 sites" );

    # Try description + wildcard.
    ok( $sites = Bric::Biz::Site->href
        ({ description => "$init{description}%" }),
        "List description '$init{description}%'" );
    is( scalar keys %$sites, 5, "Check for 5 sites" );

    # Try a bogus description.
    is_deeply( Bric::Biz::Site->href({ description => -1 }), {}, 
        "List bogus description" );

    # Try domain_name.
    $sites = Bric::Biz::Site->href({ domain_name => $init{domain_name} });
    is( scalar keys %$sites, 0, "Check for 0 sites" );

    # Try domain_name + wildcard.
    ok( $sites = Bric::Biz::Site->href({ domain_name => "ww%" }),
        "List domain_name 'ww%'" );
    # There are 6 because the default site is 'www.example.com'.
    is( scalar keys %$sites, 6, "Check for 6 sites" );

    # Try a bogus domain_name.
    is_deeply( Bric::Biz::Site->href({ domain_name => -1 }), {},
        "List bogus domain name" );

    # Try grp_id.
    my $grp = $self->{test_grp};
    my $grp_id = $grp->get_id;
    ok( $sites = Bric::Biz::Site->href({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id'" );
    is( scalar keys %$sites, 3, "Check for 3 sites" );

    # Try active.
    ok( $sites = Bric::Biz::Site->href({ active => 1}), "List active => 1" );
    is( scalar keys %$sites, 6, "Check for 6 sites" );

    # Deactivate one and make sure it doesn't come back.
    ok( $self->{test_sites}[0]->deactivate->save,
        "Deactivate and save a site" );
    ok( $sites = Bric::Biz::Site->href({ active => 1}),
        "List active => 1 again" );
    is( scalar keys %$sites, 5, "Check for 5 sites" );
}

##############################################################################
# Test class methods.
##############################################################################
# Test list().
sub test_list_ids : Test(24) {
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
    is( $site->get_asset_grp->get_id, $site->get_id,
        "Check asset group ID is ID" );
    ok( my $grp_ids = $site->get_grp_ids, "Get group IDs" );
    isa_ok( $grp_ids, 'ARRAY', "Check group IDs are in an array" );
    # There could be other group IDs, but we can't know what they are now.
    ok( scalar @$grp_ids >= 1, "Check for at least one group ID" );
    ok( $site->save, "Save site" );

    # Look it up in the database and verify the values.
    ok( $site = $site->lookup({ id => $site->get_id }), "Look up site" );
    is( $site->get_name, $name, "Check name" );
    is( $site->get_domain_name, $dn, "Check domain name" );
    is( $site->get_description, $desc, "Check description" );
    ok( $site->is_active, "Check is active" );
    is( $site->get_asset_grp->get_id, $site->get_id,
        "Check asset group ID is ID" );
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
    is( $site->get_asset_grp->get_id, $site->get_id,
        "Check asset group ID is ID" );
    ok( eq_set( scalar $site->get_grp_ids, $grp_ids), "Check group IDs" );
}


##############################################################################
# Test permission groups.
sub test_grps : Test(75) {
    my $self = shift;
    my $site = $self->{test_sites}[0];
    # Look at a site we've created.
    compare_grps($site);

    # Look at the default site.
    ok( $site = Bric::Biz::Site->lookup({ id => 100 }),
        "Look up default site" );
    compare_grps($site);
}

##############################################################################
# Test Permissions.
sub test_privs : Test(45) {
    my $self = shift;
    my $site = $self->{test_sites}[0];
    compare_privs($site);

    # Make sure the same is true for the default site.
    ok( $site = Bric::Biz::Site->lookup({ id => 100 }),
        "Look up default site" );
    compare_privs($site);
}

##############################################################################
# Private functions.
##############################################################################
# Used by get_grps() to look at groups for different sites.
sub compare_grps {
    my $site = shift;

    # Make sure that there are four user groups for this site.
    ok( my @grps = $site->list_priv_grps, "Get user groups" );
    is( scalar @grps, 4, "Check for four groups" );

    # Check their names.
    ok( my $name = $site->get_name, "Get name" );
    my $name_regex = qr/^$name/;
    foreach my $grp (@grps) {
        isa_ok($grp, 'Bric::Util::Grp::User');
        like( $grp->get_name, $name_regex, "Check name" );
        ok( $grp->get_permanent, "Check that it's permanent" );
        ok( $grp->is_secret, "Check that it's secret" );
    }

    # Change the site's name.
    ok( $site->set_name("Biggie $name"), "Change name" );
    ok( $site->save, "Save site" );

    # Load 'em up again.
    ok( @grps = $site->list_priv_grps, "Get user groups again" );
    is( scalar @grps, 4, "Check for four groups again" );

    # Check that they've been renamed.
    $name_regex = qr/^Biggie $name/;
    foreach my $grp (@grps) {
        isa_ok($grp, 'Bric::Util::Grp::User');
        like( $grp->get_name, $name_regex, "Check new name" );
    }

    # Make sure we got an asset group, too.
    ok( my $grp = $site->get_asset_grp, "Get asset group" );
    isa_ok($grp, 'Bric::Util::Grp::Asset');
    is( $grp->get_id, $site->get_id, "Check asset group ID is site ID" );
    is( $grp->get_name, 'Secret Site Asset Group', "Check site name" );

    # Reset the name.
    ok( $site->set_name($name), "Set name to '$name'" );
    ok( $site->save, "Save site with original name" );
}

##############################################################################
# Used by test_privs() to look at the privs for different sites.
sub compare_privs {
    my $site = shift;
    # Grab the permissions for this sucker.
    ok( my @privs = Bric::Util::Priv->list({ obj_grp_id => $site->get_id }),
        "List the permissions" );
    is( scalar @privs, 4, "Check for 4 permissions" );

    # Check their values. There should be one for each permission.
    my %perms = %{ Bric::Util::Priv->vals_href };
    my %seen;
    foreach my $priv (@privs) {
        ok( delete $perms{$priv->get_value}, "Get value" );
        $seen{$priv->get_id} = 1;
    }

    my $name = $site->get_name;
    my %grp_privs =
      ( "$name READ Users"   => READ,
        "$name EDIT Users"   => EDIT,
        "$name CREATE Users" => CREATE,
        "$name DENY Users"   => DENY,
      );

    # Grab the permissions associated with the user groups.
    foreach my $ugrp ($site->list_priv_grps) {
        ok( my @p = Bric::Util::Priv->list({ usr_grp_id => $ugrp->get_id }),
            "List user privs" );
        is( scalar @p, 1, "Check for one priv" );
        ok( delete $seen{$p[0]->get_id}, "Check we've seen it" );
        is( $p[0]->get_value, $grp_privs{$ugrp->get_name}, "Check value" );
    }
}

1;
__END__
