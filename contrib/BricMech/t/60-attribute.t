# Test attribute methods.
# Before `make install` is performed this script should be runnable with
# `make test`. After `make install` it should work as `perl 60-attribute.t`.

use strict;
require 5.006001;
use warnings;

use Bric::Mech;
use Test::More;

if (exists $ENV{BRICOLAGE_SERVER} && exists $ENV{BRICOLAGE_USERNAME}
      && exists $ENV{BRICOLAGE_PASSWORD}) {
    plan tests => 5;
} else {
    plan skip_all => "Bricolage env vars not set.\n"
      . "See 'README' for installation instructions.";
}

my $mech = Bric::Mech->new();
$mech->login();

# get_username, get_password (, get_server)
# - tested in 10-login.t

# in_leftnav - tested a lot

# get_workflow_menu
# - test in 20-leftnav.t

# get_lang_key
my $lang = $mech->get_lang_key;
like($lang, qr/^.{2,5}$/, "get_lang_key ($lang)");

# debug
my $debug = $mech->debug;
# get
ok(!$debug, 'debug initially false');
# croak
eval { $mech->follow_admin_link() };  # missing required arg
unlike($@, qr/ called at /, 'debug=0 croaks');
# set
$debug = $mech->debug(1);
ok($debug, 'debug sets to true');
# confess
eval { $mech->follow_admin_link() };  # missing required arg
like($@, qr/ called at /, 'debug=1 confesses');
