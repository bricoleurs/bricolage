package Bric::Util::ApacheReq::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;
use Bric::Config qw(:ssl);
use Test::MockModule;

my $CLASS = 'Bric::Util::ApacheReq';

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok($CLASS);
}

sub test_url : Test(6) {
    my $mock = Test::MockModule->new($CLASS);
    $mock->mock( instance => My::Big::Fat::Req->new );

    ok $CLASS->url, "$CLASS->url should return something";
    is $CLASS->url, 'http://www.example.com/', 'And it should be the right thing';
    is $CLASS->url( uri => '/foo'), 'http://www.example.com/foo',
        'The uri param should work';
    is $CLASS->url( uri => ''), 'http://www.example.com',
        'An empty uri param should work';
    my $s = SSL_ENABLE ? 's' : '';
    is $CLASS->url( ssl => 1), "http$s://www.example.com/",
        'The ssl param should work';
    is $CLASS->url( uri => '/foo', ssl => 1), "http$s://www.example.com/foo",
        'The uri and ssl params should work together';
}

package My::Big::Fat::Req;

sub new { bless {} => shift }
sub hostname { 'www.example.com' }

1;
