package Bric::Util::MediaType::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;
use Bric::Util::MediaType;

##############################################################################
# Test constructors.
##############################################################################
# Test new().
sub test_new : Test(5) {
    my $self = shift;
    my $exts = [qw(barby fooby)];
    my $name = 'Foo';
    my $desc = 'Bar';
    my $grp_ids = [Bric::Util::MediaType->INSTANCE_GROUP_ID];

    # Create a new MT.
    ok( my $mt = Bric::Util::MediaType->new({ name        => $name,
                                              description => $desc,
                                              ext         => $exts }),
        "Create new MT" );

    # Check its attributes.
    is( $mt->get_name, $name, "Check name" );
    is( $mt->get_description, $desc, "Check description" );
    is_deeply( [$mt->get_exts], $exts, "Check extentions" );
    is_deeply( [$mt->get_grp_ids], $grp_ids, "Check group IDs" );
}

##############################################################################
# Test class methods.
##############################################################################
# Test my_meths().
sub test_my_meths : Test(11) {
    ok( my $meths = Bric::Util::MediaType->my_meths, "Get my_meths" );
    isa_ok($meths, 'HASH', "my_meths is a hash" );
    is( $meths->{name}{type}, 'short', "Check name type" );
    ok( $meths = Bric::Util::MediaType->my_meths(1), "Get my_meths array ref" );
    isa_ok( $meths, 'ARRAY', "my_meths(1) is an array" );
    (is $meths->[0]->{name}, 'name', "Check first meth name" );

    # Try the identifier methods.
    ok( my $mt = Bric::Util::MediaType->new({ name => 'NewFoo',
                                              ext => ['foo'] }),
        "Create media type" );
    ok( my @meths = $mt->my_meths(0, 1), "Get ident meths" );
    is( scalar @meths, 1, "Check for 1 meths" );
    is( $meths[0]->{name}, 'name', "Check for 'name' meth" );
    is( $meths[0]->{get_meth}->($mt), 'NewFoo', "Check name 'NewFoo'" );
}

1;
__END__
