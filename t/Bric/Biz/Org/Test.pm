package Bric::Biz::Org::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

sub class { 'Bric::Biz::Org' };
sub new_args {
    ( name      => 'Kineticode',
      long_name => 'Kineticode, Inc.'
    )
}

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    my $self = shift;
    use_ok($self->class);
}

##############################################################################
# Test the constructor.
##############################################################################
sub test_const : Test(5) {
    my $self = shift;
    my $class = $self->class;
    my %args = my %org = $self->new_args;

    ok ( my $org = $class->new(\%args), "Test construtor" );
    ok( ! defined $org->get_id, 'Undefined ID' );
    ok( $org->is_active, "Check is active" );

    # Check the properties.
    while (my ($prop, $val) = each %org) {
        my $meth = "get_$prop";
        is( $org->$meth, $val, "Check $prop is '$val'" );
    }
}



1;
__END__
