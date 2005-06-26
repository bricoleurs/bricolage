#!/usr/bin/perl
# Test things which are required for all the tests.

use strict;
use warnings;
use Test::More 'no_plan';

BEGIN {
    use lib 't/UI';
    use_ok('TestMech');

    use_ok('Test::Harness', 2.46);         # for Test::More 'no_plan'
    use_ok('Test::WWW::Mechanize', 1.00);  # for content_contains
    use_ok('WWW::Mechanize', 1.10);        # latest version, which I used
}

# Are $ENV vars set?
like($ENV{BRICOLAGE_SERVER}, qr(^https?://.+), 'BRICOLAGE_SERVER is set');
like($ENV{BRICOLAGE_USERNAME}, qr(.{5,}),      'BRICOLAGE_USERNAME is set');
like($ENV{BRICOLAGE_PASSWORD}, qr(.{5,}),      'BRICOLAGE_PASSWORD is set');

# Is server up?
my $mech = TestMech->new(nologin => 1);
$mech->get($ENV{BRICOLAGE_SERVER});
$mech->content_contains('Bricolage', 'Bricolage server is up');

# Can we login?
$mech->login();
$mech->content_contains('sideNav', 'login succeeds');
