package Bric::SOAP::Auth::DevTest;
# Bric::SOAP::Auth client tests
# Requires Bricolage running at $ENV{BRICOLAGE_SERVER}

use strict;
use warnings;

use base qw(Bric::Test::Base);
use Test::More skip_all => "SOAP tests are under construction";

use SOAP::Lite;
import SOAP::Data 'name';
use HTTP::Cookies;


BAIL_OUT("BRICOLAGE_SERVER environment variable isn't set")
  unless exists $ENV{BRICOLAGE_SERVER};
my $server = $ENV{BRICOLAGE_SERVER};
$server = "http://$server" unless $server =~ m!^https?://!;
$server =~ s|/$||;

sub new_soap_object {
    return SOAP::Lite
      ->uri('http://bricolage.sourceforge.net/Bric/SOAP/Auth')
      ->proxy("$server/soap",
              cookie_jar => HTTP::Cookies->new());
}


sub _test_soap_object : Test(1) {
    my $soap = new_soap_object();
    isa_ok($soap, 'SOAP::Lite') or BAIL_OUT("Couldn't create SOAP::Lite object");
}

sub test_login_correct : Test(4) {
    my $test = 'Correct login';
    my $soap = new_soap_object();
    my $res = $soap->login(name(username => 'admin'),
                           name(password => 'change me now!'));

    is($res->result, 1, "$test: returns 1");

    ok(! $res->fault, "$test: has no fault string");

    my $cookie_header = $soap->transport->http_response->header('Set-Cookie');
    like($cookie_header, qr/BRICOLAGE_AUTH/, "$test: auth cookie set");

    # See if calling another method works with the auth cookie
    $soap->uri('http://bricolage.sourceforge.net/Bric/SOAP/Site');
    $res = $soap->list_ids();    # (bric_soap site list_ids)
    is_deeply($res->result, ['100'], "$test: auth cookie works");
}

sub test_login_nopass : Test(3) {
    my $test = 'Login without password';
    my $soap = new_soap_object();
    my $res = $soap->login(name(username => 'admin'));

    isnt($res->result, 1, "$test: doesn't return 1");

    my $detail = $res->faultdetail->{Bric__Util__Fault__Exception__AP};
    is($detail, "Bric::SOAP::Auth::login : missing required parameter 'password'",
       "$test: has expected fault detail");

    my $cookie_header = $soap->transport->http_response->header('Set-Cookie');
    unlike($cookie_header, qr/BRICOLAGE_AUTH/, "$test: auth cookie not set");
}

sub test_login_nouser : Test(3) {
    my $test = 'Login without username';
    my $soap = new_soap_object();
    my $res = $soap->login(name(password => 'change me now!'));

    isnt($res->result, 1, "$test: doesn't return 1");

    my $detail = $res->faultdetail->{Bric__Util__Fault__Exception__AP};
    is($detail, "Bric::SOAP::Auth::login : missing required parameter 'username'",
       "$test: has expected fault detail");

    my $cookie_header = $soap->transport->http_response->header('Set-Cookie');
    unlike($cookie_header, qr/BRICOLAGE_AUTH/, "$test: auth cookie not set");
}

sub test_login_nouserorpass : Test(3) {
    my $test = 'Login without username or password';
    my $soap = new_soap_object();
    my $res = $soap->login();

    isnt($res->result, 1, "$test: doesn't return 1");

    my $detail = $res->faultdetail->{Bric__Util__Fault__Exception__AP};
    like($detail, qr/Bric::SOAP::Auth::login : missing required parameter /,
         "$test: has expected fault detail");

    my $cookie_header = $soap->transport->http_response->header('Set-Cookie');
    unlike($cookie_header, qr/BRICOLAGE_AUTH/, "$test: auth cookie not set");
}

sub test_login_baduser : Test(3) {
    my $test = 'Login with bad username';
    my $soap = new_soap_object();
    my $res = $soap->login(name(username => 'notauser'),
                           name(password => 'change me now!'));

    isnt($res->result, 1, "$test: doesn't return 1");

    my $detail = $res->faultdetail->{Bric__Util__Fault__Exception__AP};
    like($detail, qr/Bric::SOAP::Auth::login : login failed : Invalid username or password/,
         "$test: has expected fault detail");

    my $cookie_header = $soap->transport->http_response->header('Set-Cookie');
    unlike($cookie_header, qr/BRICOLAGE_AUTH/, "$test: auth cookie not set");
}

sub test_login_badpass : Test(3) {
    my $test = 'Login with bad password';
    my $soap = new_soap_object();
    my $res = $soap->login(name(username => 'admin'),
                           name(password => 'change me later...'));

    isnt($res->result, 1, "$test: doesn't return 1");

    my $detail = $res->faultdetail->{Bric__Util__Fault__Exception__AP};
    like($detail, qr/Bric::SOAP::Auth::login : login failed : Invalid username or password/,
         "$test: has expected fault detail");

    my $cookie_header = $soap->transport->http_response->header('Set-Cookie');
    unlike($cookie_header, qr/BRICOLAGE_AUTH/, "$test: auth cookie not set");
}


1;
