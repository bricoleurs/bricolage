package Bric::Dist::ServerType::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Dist::ServerType');
}

##############################################################################
# Test the constructor.
##############################################################################
sub test_const : Test(10) {
    my $self = shift;
    my $args = { name        => 'Bogus',
                 description => 'Bogus ServerType',
                 move_method => 'File System',
                 site_id     => 100,
               };

    ok ( my $st = Bric::Dist::ServerType->new($args), "Test construtor" );
    ok( ! defined $st->get_id, 'Undefined ID' );
    is( $st->get_name, $args->{name}, "Name is '$args->{name}'" );
    is( $st->get_description, $args->{description},
        "Description is '$args->{description}'" );
    is( $st->get_site_id, 100, "Check site ID is '$args->{site_id}'" );
    is( $st->get_move_method, $args->{move_method},
        "Move method is '$args->{move_method}'" );
    ok( $st->is_active, "Check that it's activated" );
    ok( $st->can_publish, "Check can publish" );
    ok( !$st->can_preview, "Check can't preview" );
    ok( !$st->can_copy, "Check can't copy" );
}

##############################################################################
# Test class methods.
##############################################################################
# Test my_meths().
sub test_my_meths : Test(11) {
    ok( my $meths = Bric::Dist::ServerType->my_meths, "Get my_meths" );
    isa_ok($meths, 'HASH', "my_meths is a hash" );
    is( $meths->{name}{type}, 'short', "Check name type" );
    ok( $meths = Bric::Dist::ServerType->my_meths(1), "Get my_meths array ref" );
    isa_ok( $meths, 'ARRAY', "my_meths(1) is an array" );
    (is $meths->[0]->{name}, 'name', "Check first meth name" );

    # Try the identifier methods.
    ok( my $st = Bric::Dist::ServerType->new({ name => 'NewFoo' }),
        "Create destination" );
    ok( my @meths = $st->my_meths(0, 1), "Get ident meths" );
    is( scalar @meths, 1, "Check for 1 meth" );
    is( $meths[0]->{name}, 'name', "Check for 'name' meth" );
    is( $meths[0]->{get_meth}->($st), 'NewFoo', "Check name 'NewFoo'" );
}

1;
__END__
