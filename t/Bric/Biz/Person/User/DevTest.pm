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

sub test_lookup : Test(+2) {
    my $self = shift;
    $self->SUPER::test_lookup(@_);
    my $class = $self->test_class;
    my %args = $self->new_args;

    # Look up the login in the database.
    ok( my $u = $class->lookup({ login => $args{login} }),
        "Look up $args{login}" );
    is( $u->get_login, $args{login}, "Check that login is the same" );
}

sub test_list : Test(+2) {
    my $self = shift;
    $self->SUPER::test_list(@_);
    my $class = $self->test_class;
    my %args = $self->new_args;

    # Try login.
    ok( my @users = $class->list({ login => "$args{login}%" }),
        "Look up login '$args{login}%" );
    is( scalar @users, 5, "Check for 5 persons" );
}


1;
__END__
