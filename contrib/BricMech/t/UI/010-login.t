#!/usr/bin/perl
# Test logging in and out.

use strict;
use warnings;
use Test::More 'no_plan';

use lib 't/UI';
use TestMech;

my $mech = TestMech->new();

# Can we login?
$mech->content_contains('sideNav', 'login succeeds');

# Can we logout?
$mech->get("$ENV{BRICOLAGE_SERVER}/logout");
$mech->content_contains('Please log in', 'logout succeeds');

# Can we login if the username or password is bogus?
$mech->login(username => 'exc33dinglyunl1k3lyus3rname');
$mech->content_contains('Invalid username or password',
                        'login with bogus username fails');

$mech->login(password => 'exc33dinglyunl1k3lypassw0rd');
$mech->content_contains('Invalid username or password',
                        'login with bogus password fails');
