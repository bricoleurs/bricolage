package Bric::Biz::Person::User::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;
use Test::MockModule;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Biz::Person::User');
}

my $name = { lname  => 'Wheeler',
             fname  => 'David',
             suffix => 'MA',
             prefix => 'Mr.',
             login  => 'shaz',
             mname  => 'Erin' };

my $pw = 'W#$gni Q# #fd93r diiGFn34 i';

##############################################################################
# Test the constructor.
##############################################################################
sub test_const : Test(13) {
    my $self = shift;

    ok ( my $u = Bric::Biz::Person::User->new($name), "Test construtor" );
    ok( ! defined $u->get_id, 'Undefined ID' );
    is( $u->get_lname, $name->{lname}, "Last name is '$name->{lname}'" );
    is( $u->get_fname, $name->{fname}, "First name is '$name->{fname}'" );
    is( $u->get_mname, $name->{mname}, "Middle name is '$name->{mname}'" );
    is( $u->get_prefix, $name->{prefix}, "Prefix is '$name->{prefix}'" );
    is( $u->get_suffix, $name->{suffix}, "Suffix is '$name->{suffix}'" );
    is( $u->get_login, $name->{login}, "Login is '$name->{login}'" );
    ok( $u->is_active, "Person is active" );
    is( $u->format_name("%p% f% M% l%, s"), 'Mr. David E. Wheeler, MA',
        'Check formatted name');

    # Make sure that we fake out LDAP auth, in case that's how it's configured.
    my $ldap_mock = Test::MockModule->new('Bric::Util::AuthLDAP', no_auto => 1);
    my @retvals = (1, 0);
    $ldap_mock->mock(authenticate => sub { shift @retvals });

    # Test the password.
    ok( $u->set_password($pw), "Set password" );
    ok( $u->chk_password($pw), "Check password" );
    ok( ! $u->chk_password($pw . 'foo'), "Check bad password" );
}

##############################################################################
# Test class methods.
##############################################################################
# Test my_meths().
sub test_my_meths : Test(11) {
    ok( my $meths = Bric::Biz::Person::User->my_meths, "Get my_meths" );
    isa_ok($meths, 'HASH', "my_meths is a hash" );
    is( $meths->{name}{type}, 'short', "Check name type" );
    ok( $meths = Bric::Biz::Person::User->my_meths(1), "Get my_meths array ref" );
    isa_ok( $meths, 'ARRAY', "my_meths(1) is an array" );
    (is $meths->[0]->{name}, 'prefix', "Check first meth name" );

    # Try the identifier methods.
    ok( my $u = Bric::Biz::Person::User->new({ login => 'fooey' }),
        "Create User" );
    ok( my @meths = $u->my_meths(0, 1), "Get ident meths" );
    is( scalar @meths, 1, "Check for 1 meth" );
    is( $meths[0]->{name}, 'login', "Check for 'login' meth" );
    is( $meths[0]->{get_meth}->($u), 'fooey', "Check login 'fooey'" );
}

1;
__END__
