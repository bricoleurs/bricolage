# Test profile methods.
# Before `make install` is performed this script should be runnable with
# `make test`. After `make install` it should work as `perl 40-profile.t`.

use strict;
require 5.006001;
use warnings;

use Bric::Mech;
use Test::More;

if (exists $ENV{BRICOLAGE_SERVER} && exists $ENV{BRICOLAGE_USERNAME}
      && exists $ENV{BRICOLAGE_PASSWORD}) {
#    plan tests => 17;
    plan skip_all => 'profile tests not started';
} else {
    plan skip_all => "Bricolage env vars not set.\n"
      . "See 'README' for installation instructions.";
}

#    my $mech = Bric::Mech->new();
#    $mech->login();
