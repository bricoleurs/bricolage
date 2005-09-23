package Bric::Biz::ElementType::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(2) {
    use_ok('Bric::Biz::ElementType::Parts::FieldType');
    use_ok('Bric::Biz::ElementType');
}

##############################################################################
# Test class methods.
##############################################################################
# Test my_meths().
sub test_my_meths : Test(11) {
    ok( my $meths = Bric::Biz::ElementType->my_meths, "Get my_meths" );
    isa_ok($meths, 'HASH', "my_meths is a hash" );
    is( $meths->{name}{type}, 'short', "Check name type" );
    ok( $meths = Bric::Biz::ElementType->my_meths(1), "Get my_meths array ref" );
    isa_ok( $meths, 'ARRAY', "my_meths(1) is an array" );
    (is $meths->[0]->{name}, 'name', "Check first meth name" );

    # Try the identifier methods.
    ok( my $elem = Bric::Biz::ElementType->new({ key_name => 'new_at' }),
        "Create Element" );
    ok( my @meths = $elem->my_meths(0, 1), "Get ident meths" );
    is( scalar @meths, 1, "Check for 1 meth" );
    is( $meths[0]->{name}, 'key_name', "Check for 'key_name' meth" );
    is( $meths[0]->{get_meth}->($elem), 'new_at', "Check name 'new_at'" );
}

1;
__END__
