# Test workspace methods.
# Before `make install` is performed this script should be runnable with
# `make test`. After `make install` it should work as `perl 50-workspace.t`.

use strict;
require 5.006001;
use warnings;

#use Test::More tests => 0;    # must match `skip' below
use Test::More skip_all => 'workspace tests not done';
use Bric::Mech;

SKIP: {
    my $msg = "Bricolage env vars not set.\n"
      . "See 'README' for installation instructions.";
    skip($msg, 0) unless exists $ENV{BRICOLAGE_SERVER}
      && exists $ENV{BRICOLAGE_USERNAME} && exists $ENV{BRICOLAGE_PASSWORD};

#    my $mech = Bric::Mech->new();
#    $mech->login();
}
