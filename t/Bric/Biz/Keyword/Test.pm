package Bric::Biz::Keyword::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Bric::Biz::Keyword;
use Test::More;

##############################################################################
# Test constructors.
##############################################################################
# Test new().
sub test_new : Test(21) {
    my $self = shift;
    ok( my $keyword = Bric::Biz::Keyword->new, "Construct new keyword" );
    ok( !defined $keyword->get_id, "Check for undef id" );
    ok( !defined $keyword->get_name, "Check for undef name" );
    ok( !defined $keyword->get_screen_name, "Check for undef screen name" );
    ok( !defined $keyword->get_sort_name, "Check for undef sort name" );
    ok( $keyword->is_active, "Check keyword is active" );

    # Don't mess with name it forces a database lookup to ensure uniqueness.

    # Mess with the screen_name.
    ok( $keyword->set_screen_name('desc'), "Set screen name to 'desc'" );
    is( $keyword->get_screen_name, 'desc', "Check screen name 'desc'" );
    ok( $keyword->set_screen_name('foo'), "Set screen name to 'foo'" );
    is( $keyword->get_screen_name, 'foo', "Check screen name 'foo'" );

    # Mess with the sort_name.
    ok( $keyword->set_sort_name('desc'), "Set sort name to 'desc'" );
    is( $keyword->get_sort_name, 'desc', "Check sort name 'desc'" );
    ok( $keyword->set_sort_name('foo'), "Set sort name to 'foo'" );
    is( $keyword->get_sort_name, 'foo', "Check sort name 'foo'" );

    # Mess with the active attribute.
    ok( $keyword->deactivate, "Deactivate keyword" );
    ok( !$keyword->is_active, "Keyword is deactivated" );
    ok( $keyword->activate, "Reactivate keyword" );
    ok( $keyword->is_active, "Check keyword is active again" );

    # Verify initial group membership.
    ok( my @grp_ids = $keyword->get_grp_ids, "Get group IDs" );
    is( scalar @grp_ids, 1, "Check for 1 group ID" );
    is( $grp_ids[0], 50, "Check for group ID 50" );
}

##############################################################################
# Test class methods.
##############################################################################
# Test my_meths().
sub test_my_meths : Test(11) {
    ok( my $meths = Bric::Biz::Keyword->my_meths, "Get my_meths" );
    isa_ok($meths, 'HASH', "my_meths is a hash" );
    is( $meths->{name}{type}, 'short', "Check name type" );
    ok( $meths = Bric::Biz::Keyword->my_meths(1), "Get my_meths array ref" );
    isa_ok( $meths, 'ARRAY', "my_meths(1) is an array" );
    (is $meths->[0]->{name}, 'name', "Check first meth name" );

    # Try the identifier methods.
    ok( my $kw = Bric::Biz::Keyword->new({ name => 'NewFoo' }),
        "Create Keyword" );
    ok( my @meths = $kw->my_meths(0, 1), "Get ident meths" );
    is( scalar @meths, 1, "Check for 1 meth" );
    is( $meths[0]->{name}, 'name', "Check for 'name' meth" );
    is( $meths[0]->{get_meth}->($kw), 'NewFoo', "Check name 'NewFoo'" );
}

##############################################################################
# Test group methods.
sub test_grp : Test(5) {
    my $self = shift;
    is( Bric::Biz::Keyword->GROUP_PACKAGE, 'Bric::Util::Grp::Keyword',
        "Check group package" );
    is( Bric::Biz::Keyword->INSTANCE_GROUP_ID, 50, "Check group instance" );
    ok( my @grp_ids = Bric::Biz::Keyword->get_grp_ids, "Get group IDs" );
    is( scalar @grp_ids, 1, "Check for 1 group ID" );
    is( $grp_ids[0], 50, "Check for group ID 47" );
}

1;
__END__
