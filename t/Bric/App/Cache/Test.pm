package Bric::App::Cache::Test;

use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;
use Bric::App::Cache;

##############################################################################
# Setup and teardown methods.
##############################################################################
# Create a new cache object.
sub setup_cache : Test(setup => 1) {
    my $self = shift;
    ok( my $c = Bric::App::Cache->new, "Construct new cache" );
    $self->{cache} = $c;
}

##############################################################################
# Clear out the cache.
sub teardown_cache : Test(teardown => 1) {
    ok( Bric::App::Cache->clear, "Tear down cache" );
}

##############################################################################
# Test Constructors.
##############################################################################
# Test new().
sub test_new : Test(4) {
    my $self = shift;
    my $c = $self->{cache};
    ok( $c->set('foo', 'bar'), "Set 'foo' to 'bar'" );
    is( $c->get('foo'), 'bar', "Check that 'foo' is 'bar'" );

    # Create it again, just to be sure it persisted.
    ok( $c = Bric::App::Cache->new, "Construct cache again" );
    is( $c->get('foo'), 'bar', "Check that 'foo' is 'bar'" );
}

##############################################################################
# Test class methods.
##############################################################################
# Test clear().
sub test_clear : Test(5) {
    my $self = shift;
    my $c = $self->{cache};
    ok( $c->set('hey', 'you'), "Set 'hey' to 'you'" );
    is( $c->get('hey'), 'you', "Check that 'hey' is 'you'" );
    ok( Bric::App::Cache->clear, "Clear cache" );
    ok( $c = Bric::App::Cache->new, "Construct cache again" );
    ok( ! defined $c->get('hey'), "Check that 'hey' is undefined" );
}

##############################################################################
# Test instance methods.
##############################################################################
# Test the lmu_time methods.
sub test_lmu : Test(3) {
    my $self = shift;
    my $c = $self->{cache};
    ok( ! defined $c->get_lmu_time, "No lmu_time, yet" );
    ok( $c->set_lmu_time, "Set lmu_time" );
    ok( $c->get_lmu_time >= time, "Check lmu_time" );
}

##############################################################################
# Test the user_cx methods.
sub test_user_cx : Test(3) {
    my $self = shift;
    my $c = $self->{cache};
    my $uid = $self->user_id;
    my $sid = 100;
    ok( ! defined $c->get_user_cx($uid), "No user_cx yet" );
    ok( $c->set_user_cx($uid, $sid), "Set user_cx" );
    is( $c->get_user_cx($uid), $sid, "Check user_cx" );
}

1;
__END__
