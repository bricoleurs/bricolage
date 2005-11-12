package Bric::Biz::InputChannel::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;
use Bric::Config;
use Bric::Biz::Asset::Business::Story;
use Bric::Biz::Asset::Business::Media;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Biz::InputChannel');
}

##############################################################################
# Test constructors.
##############################################################################
# Test the new() method.
sub test_new : Test(8) {
    ok( my $ic = Bric::Biz::InputChannel->new, "Create new IC" );
    isa_ok($ic, 'Bric::Biz::InputChannel');
    isa_ok($ic, 'Bric');

    # Try new() with parameters.
    my $param = { name        => 'mike\'s test5',
                  description => 'a fun test',
                  active      => 1
                };

    ok( $ic = Bric::Biz::InputChannel->new($param),
        "Create new IC with params" );
    is( $ic->get_name, "mike's test5", "Check name" );
    is( $ic->get_description, 'a fun test', "Check description" );
    ok( $ic->is_active, "Check is_active" );
}

##############################################################################
# Test class methods.
##############################################################################
# Test my_meths().
sub test_my_meths : Test(11) {
    ok( my $meths = Bric::Biz::InputChannel->my_meths, "Get my_meths" );
    isa_ok($meths, 'HASH', "my_meths is a hash" );
    is( $meths->{name}{type}, 'short', "Check name type" );
    ok( $meths = Bric::Biz::InputChannel->my_meths(1), "Get my_meths array ref" );
    isa_ok( $meths, 'ARRAY', "my_meths(1) is an array" );
    (is $meths->[0]->{name}, 'name', "Check first meth name" );

    # Try the identifier methods.
    ok( my $ic = Bric::Biz::InputChannel->new({ name => 'NewFoo' }),
        "Create IC" );
    ok( my @meths = $ic->my_meths(0, 1), "Get ident meths" );
    is( scalar @meths, 1, "Check for 1 meth" );
    is( $meths[0]->{name}, 'name', "Check for 'name' meth" );
    is( $meths[0]->{get_meth}->($ic), 'NewFoo', "Check name 'NewFoo'" );
}

1;
__END__
