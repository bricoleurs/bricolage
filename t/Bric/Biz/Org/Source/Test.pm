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
1;
__END__
