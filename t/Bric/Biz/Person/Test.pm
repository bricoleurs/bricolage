package Bric::Biz::Person::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Biz::Person');
}

##############################################################################
# Test the constructor.
##############################################################################
sub test_const : Test(9) {
    my $self = shift;
    my $name = { lname => 'Wheeler',
                 fname => 'David',
                 suffix => 'MA',
                 prefix => 'Mr.',
                 mname => 'Erin'};

    ok ( my $p = Bric::Biz::Person->new($name), "Test construtor" );
    ok( ! defined $p->get_id, 'Undefined ID' );
    is( $p->get_lname, $name->{lname}, "Last name is '$name->{lname}'" );
    is( $p->get_fname, $name->{fname}, "First name is '$name->{fname}'" );
    is( $p->get_mname, $name->{mname}, "Middle name is '$name->{mname}'" );
    is( $p->get_prefix, $name->{prefix}, "Prefix is '$name->{prefix}'" );
    is( $p->get_suffix, $name->{suffix}, "Suffix is '$name->{suffix}'" );
    ok( $p->is_active, "Person is active" );
    is( $p->format_name("%p% f% M% l%, s"), 'Mr. David E. Wheeler, MA',
        'Check formatted name');
}

1;
__END__
