package Bric::Biz::Org::Person::Test;
use strict;
use warnings;
use base qw(Bric::Biz::Org::Test);
use Test::More;

sub class { 'Bric::Biz::Org::Person' };
sub new_args {
    my $self = shift;
    ( $self->SUPER::new_args,
      person_id => $self->user_id,
      org_id => 1,
      role => 'Grunt',
      title => 'Tech Writer',
      department => 'IT'
    )
}

sub test_const : Test(+5) { shift->SUPER::test_const }

1;
__END__
