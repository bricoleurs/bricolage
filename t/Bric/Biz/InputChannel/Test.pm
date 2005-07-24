package Bric::Biz::InputChannel::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;
use Bric::Config qw(:oc);
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
sub test_new : Test(10) {
    ok( my $ic = Bric::Biz::InputChannel->new, "Create new IC" );
    isa_ok($ic, 'Bric::Biz::InputChannel');
    isa_ok($ic, 'Bric');
    isa_ok($ic, 'Exporter');

    # Try new() with parameters.
    my $param = { key_name    => 'test_ic',
                  name        => 'test ic',
                  description => 'a test',
                  site_id     => 100,
                  active      => 1
                };

    ok( $ic = Bric::Biz::InputChannel->new($param),
        "Create new IC with params" );
    is( $ic->get_key_name, "test_ic", "Check key name");
    is( $ic->get_name, "test ic", "Check name" );
    is( $ic->get_description, 'a test', "Check description" );
    is( $ic->get_site_id, 100, "Check site ID" );
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
    (is $meths->[0]->{name}, 'key_name', "Check first meth name" );

    # Try the identifier methods.
    ok( my $ic = Bric::Biz::InputChannel->new({ key_name => 'NewFoo' }),
        "Create IC" );
    ok( my @meths = $ic->my_meths(0, 1), "Get ident meths" );
    is( scalar @meths, 1, "Check for 1 meth" );
    is( $meths[0]->{name}, 'key_name', "Check for 'name' meth" );
    is( $meths[0]->{get_meth}->($ic), 'NewFoo', "Check key_name 'NewFoo'" );
}

1;
__END__
