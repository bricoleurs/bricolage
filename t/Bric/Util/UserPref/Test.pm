package Bric::Util::UserPref::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Util::UserPref');
}

##############################################################################
# Test class methods.
##############################################################################
# Test my_meths().
sub test_my_meths : Test(7) {
    ok( my $meths = Bric::Util::UserPref->my_meths, "Get my_meths" );
    isa_ok($meths, 'HASH', "my_meths is a hash" );
    is( $meths->{value}{type}, 'short', "Check value type" );
    ok( $meths = Bric::Util::UserPref->my_meths(1), "Get my_meths array ref" );
    isa_ok( $meths, 'ARRAY', "my_meths(1) is an array" );
    is( $meths->[0]->{name}, 'pref_id', "Check first meth name" );

    # Try the identifier methods.
    ok( my $pref = Bric::Util::UserPref->new({ user_id => 0, pref_id => 1 }),
        "Create user preference" );
}

1;

