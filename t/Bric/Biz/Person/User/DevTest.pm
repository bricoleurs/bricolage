package Bric::Biz::Person::User::DevTest;
use strict;
use warnings;
use base qw(Bric::Biz::Person::DevTest);
use Bric::Biz::Person::User;
use Bric::Util::Grp::User;
use Test::More;

# Commented out because it's handled by the FK to the person table in the
# super class.
#sub table { 'usr' };

sub test_class { 'Bric::Biz::Person::User' }
sub test_grp_class { 'Bric::Util::Grp::User' }
sub new_args {
    ( shift->SUPER::new_args,
      login => 'shaz',
      password => '#$infn 83rfn; faser aweff',
    )
}

sub munge {
    my ($self, $args, $n) = @_;
    $args->{login} .= $n;
    $self->SUPER::munge($args, $n);
}


1;
__END__
