package Bric::Biz::Site::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;
use Bric::Biz::Site;

##############################################################################
# Test constructors.
##############################################################################
# Test new().
sub test_new : Test(17) {
    my $self = shift;
    ok( my $site = Bric::Biz::Site->new, "Construct new site" );
    ok( !defined $site->get_id, "Check for undef id" );
    ok( !defined $site->get_name, "Check for undef name" );
    ok( !defined $site->get_description, "Check for undef description" );
    ok( !defined $site->get_domain_name, "Check for undef domain_name" );
    ok( $site->is_active, "Check site is active" );

    # Don't mess with name or domain_name because they force database lookups
    # to ensure uniqueness.

    # Mess with the description.
    ok( $site->set_description('desc'), "Set description to 'desc'" );
    is( $site->get_description, 'desc', "Check description 'desc'" );
    ok( $site->set_description('foo'), "Set description to 'foo'" );
    is( $site->get_description, 'foo', "Check description 'foo'" );

    # Mess with the active attribute.
    ok( $site->deactivate, "Deactivate site" );
    ok( !$site->is_active, "Site is deactivated" );
    ok( $site->activate, "Reactivate site" );
    ok( $site->is_active, "Check site is active again" );

    # Verify initial group membership.
    ok( my @grp_ids = $site->get_grp_ids, "Get group IDs" );
    is( scalar @grp_ids, 1, "Check for 1 group ID" );
    is( $grp_ids[0], 47, "Check for group ID 47" );
}


##############################################################################
# Test class methods.
##############################################################################
# Test my_meths().
sub test_my_meths : Test(17) {
    ok( my $meths = Bric::Biz::Site->my_meths, "Get my_meths" );
    isa_ok($meths, 'HASH', "my_meths is a hash" );
    is( $meths->{name}{disp}, 'Name', "Check name display name" );
    ok( $meths = Bric::Biz::Site->my_meths(1), "Get my_meths array ref" );
    isa_ok( $meths, 'ARRAY', "my_meths(1) is an array" );
    (is $meths->[0]->{name}, 'name', "Check first meth name" );

    # Try fetching a value.
    ok( my $site = Bric::Biz::Site->new({ description => 'Big Site' }),
        "Create site" );
    ok( my $meth = Bric::Biz::Site->my_meths->{description},
        "Get description meth" );
    is( $meth->{name}, "description", "Check description meth name" );
    is( $meth->{get_meth}->($site), 'Big Site',
        "Check description get_meth" );

    # Try setting a value.
    ok( $meth->{set_meth}->($site, 'Little Site'), "Set description" );
    is( $site->get_description, 'Little Site', "Check site description" );
    is( $meth->{get_meth}->($site), 'Little Site',
        "Check description get_meth again" );

    # Try the identifier methods.
    ok( my @meths = Bric::Biz::Site->my_meths(0, 1), "Get ident meths" );
    is( scalar @meths, 2, "Check for 2 meths" );
    is( $meths[0]->{name}, 'name', "Check for 'name' meth" );
    is( $meths[1]->{name}, 'domain_name', "Check for 'domain_name' meth" );
}

##############################################################################
# Test group methods.
sub test_grp : Test(5) {
    my $self = shift;
    is( Bric::Biz::Site->GROUP_PACKAGE, 'Bric::Util::Grp::Site',
        "Check group package" );
    is( Bric::Biz::Site->INSTANCE_GROUP_ID, 47, "Check group instance" );
    ok( my @grp_ids = Bric::Biz::Site->get_grp_ids, "Get group IDs" );
    is( scalar @grp_ids, 1, "Check for 1 group ID" );
    is( $grp_ids[0], 47, "Check for group ID 47" );
}

1;
__END__
