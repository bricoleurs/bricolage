package Bric::Biz::Org::Source::Test;
use strict;
use warnings;
use base qw(Bric::Biz::Org::Test);
use Test::More;

sub class { 'Bric::Biz::Org::Source' };
sub new_args {
    my $self = shift;
    ( $self->SUPER::new_args,
      source_name => 'Kineticode 10-day',
      description => '10 day Kineticode lease',
      expire      => 10
    )
}

sub test_const : Test(+3) { shift->SUPER::test_const }

##############################################################################
# Test class methods.
##############################################################################
# Test my_meths().
sub test_my_meths : Test(11) {
    ok( my $meths = Bric::Biz::Org::Source->my_meths, "Get my_meths" );
    isa_ok($meths, 'HASH', "my_meths is a hash" );
    is( $meths->{name}{type}, 'short', "Check name type" );
    ok( $meths = Bric::Biz::Org::Source->my_meths(1),
        "Get my_meths array ref" );
    isa_ok( $meths, 'ARRAY', "my_meths(1) is an array" );
    (is $meths->[0]->{name}, 'name', "Check first meth name" );

    # Try the identifier methods.
    ok( my $source = Bric::Biz::Org::Source->new({ source_name => 'NewFoo' }),
        "Create Source" );
    ok( my @meths = $source->my_meths(0, 1), "Get ident meths" );
    is( scalar @meths, 1, "Check for 1 meth" );
    is( $meths[0]->{name}, 'source_name', "Check for 'source_name' meth" );
    is( $meths[0]->{get_meth}->($source), 'NewFoo',
        "Check source_name 'NewFoo'" );
}

1;
__END__
