#!/usr/bin/perl -w

=head1 NAME

Auth.pl - a test script for Bric::SOAP::Story

=head1 SYNOPSIS

  $ ./Auth.pl
  ok 1 ...

=head1 DESCRIPTION

This is a Test::More test script for the Bric::SOAP::Auth module.

==head1 CONSTANTS

=over 4

=item DEBUG

Set this to 1 to see debugging text including the full XML for every
SOAP method call and response.  Highly educational.

=item USER

Set this to a working login.

=item PASSWORD

Set this to the password for the USER account.

=back

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

=cut

use strict;
use constant DEBUG => 1;

use constant USER     => 'admin';
use constant PASSWORD => 'bric';

use Test::More qw(no_plan);
use SOAP::Lite (DEBUG ? (trace => [qw(debug)]) : ());
import SOAP::Data 'name';
use Data::Dumper;
use HTTP::Cookies;

# setup soap object
my $soap = new SOAP::Lite
    uri => 'http://bricolage.sourceforge.net/Bric/SOAP/Auth',
    readable => DEBUG;
$soap->proxy('http://localhost/soap',
	     cookie_jar => HTTP::Cookies->new(ignore_discard => 1));
isa_ok($soap, 'SOAP::Lite');

# try a bad login attempt
my $response = $soap->login(name(username => USER), 
			    name(password => rand()));
ok($response->fault, 'bad login failed');
like($response->faultstring(), qr/Invalid username or password/, "bad login message check");

# try real login
$response = $soap->login(name(username => USER), 
			 name(password => PASSWORD));
ok(!$response->fault, 'fault check');

my $success = $response->result;
ok($success, "login success");

# print STDERR "COOKIE JAR: ", $cookie_jar->as_string, "\n";

# try making a call using the creds
$soap->uri('http://bricolage.sourceforge.net/Bric/SOAP/Story');
$response = $soap->list_ids();
ok(!$response->fault, 'fault check');
my $list = $response->result;
isa_ok($list, 'ARRAY');
ok(@$list, 'retrieved story ids from list_id');
