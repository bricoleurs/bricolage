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
    my $port = LISTEN_PORT == 80 ? '' : ':' . LISTEN_PORT;

    ok $CLASS->url, "$CLASS->url should return something";
    is $CLASS->url, "http://www.example.com$port/", 'And it should be the right thing';
    is $CLASS->url( uri => '/foo'), "http://www.example.com$port/foo",
        'The uri param should work';
    is $CLASS->url( uri => ''), "http://www.example.com$port",
        'An empty uri param should work';
    my $s = '';
    if (SSL_ENABLE) {
        $s = 's';
        $port = SSL_PORT == 443 ? '' : ':' . SSL_PORT;
    }
    is $CLASS->url( ssl => 1), "http$s://www.example.com$port/",
        'The ssl param should work';
    is $CLASS->url( uri => '/foo', ssl => 1), "http$s://www.example.com$port/foo",
        'The uri and ssl params should work together';
}

package My::Big::Fat::Req;

sub new { bless {} => shift }
sub hostname { 'www.example.com' }

1;
