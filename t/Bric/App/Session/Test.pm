package Bric::App::Session::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;
use Apache::FakeRequest;
use Bric::App::Session;

my $sess;

##############################################################################
# Setup for tests.
##############################################################################
sub test_setup : Test(setup => 1) {
    my $self = shift;
    my $r = Apache::FakeRequest->new;
    ok( Bric::App::Session::setup_user_session($r), "Setup user session" );
    # Bric::App::Session puts the session hash into the Mason::Commands
    # package, so let's just get a convenient handle to it, shall we?
    $sess = \%HTML::Mason::Commands::session
}

##############################################################################
# Test functions.
##############################################################################
sub test_session : Test(2) {
    my $self = shift;
    ok( $sess->{foo} = 'bar', "Set foo" );
    is( $sess->{foo}, 'bar', "Test for 'bar'" );
}

##############################################################################
# Bogus Apache::Cookie module for testing.
##############################################################################
package Apache::Cookie;

use strict;
use warnings;
use Bric::Config qw(AUTH_COOKIE);

my %ARGS;

sub new {
    my ($proto, $r, %args) = @_;
    %args = %ARGS unless %args;
    return undef unless %args;
    return bless \%args, ref $proto || $proto;
}

sub fetch { ( AUTH_COOKIE, Apache::Cookie->new(0, %ARGS) ) }
sub value { $_[0]->{-value} }
sub bake { %ARGS = %{$_[0]} }




1;
__END__
