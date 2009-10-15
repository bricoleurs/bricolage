package Bric::Dist::Client::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test the constructor.
##############################################################################

sub atest_load : Test {
    use_ok 'Bric::Dist::Client';
}

sub test_new : Test(no_plan) {
    ok my $client = Bric::Dist::Client->new, 'Should be able to create client';
    isa_ok $client, 'Bric::Dist::Client';
    isa_ok $client, 'Bric';
    is $client->get_timeout, Bric::Dist::Client::DEFAULT_TIMEOUT(),
        'Should have default timeout';
    ok $client->set_timeout(45), 'Set a new timeout';
    is $client->get_timeout, 45, 'It should have the new timeout';
    ok $client = Bric::Dist::Client->new( { timeout => 60 }),
        'Create with new timeout';
    is $client->get_timeout, 60, 'It should have the initial timeout';
}

1;
__END__
