package Bric::Biz::Person::User::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

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

    # Test the password.
    ok( $u->set_password($pw), "Set password" );
    ok( $u->chk_password($pw), "Check password" );
    ok( ! $u->chk_password($pw . 'foo'), "Check bad password" );
}

1;
__END__
