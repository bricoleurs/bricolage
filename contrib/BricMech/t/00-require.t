# Test basic requirements.
# Before `make install` is performed this script should be runnable with
# `make test`. After `make install` it should work as `perl 00-require.t`.

use strict;
require 5.006001;
use warnings;

use Test::More tests => 3;
BEGIN {
    require_ok('Bric::Mech');
}

my $mech = Bric::Mech->new();
isa_ok($mech, 'Bric::Mech');
isa_ok($mech, 'WWW::Mechanize');
