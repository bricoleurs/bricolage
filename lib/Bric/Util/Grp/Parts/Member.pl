#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 31;
use Carp;

BEGIN { use_ok('Bric::Util::Grp::Parts::Member') }
BEGIN { use_ok('Bric::Util::Pref') }

# Construct an instance of the Time Zone preference object's membership in the
# All Preferences group.
ok my $memb = Bric::Util::Grp::Parts::Member->lookup({ id => 401 }),
  "Lookup time zone pref member";
is $memb->get_id, 401, "Check member ID";
is $memb->get_grp_id, 22, "Check member grp ID";

# Now get a list of member objects in the All Preferences group.
ok my @memb = Bric::Util::Grp::Parts::Member->list
  ({ grp_package => 'Bric::Util::Grp::Pref' }), "Get all members";
ok @memb > 3, "Got more than three members";

# Now just get the member object for a single object.
ok @memb = Bric::Util::Grp::Parts::Member->list
  ({ grp_package    => 'Bric::Util::Grp::Pref',
     object_package => 'Bric::Util::Pref',
     object_id      => 1}),
  "Get one member";
ok @memb == 1, "Check for one member";
is $memb[0]->get_id, 401, "Check one member ID";
is $memb[0]->get_grp_id, 22, "Check one member grp ID";
is $memb[0]->get_obj_id, 1, "Check one member object ID";

# Try the same thing with an actual object.
ok my $pref = Bric::Util::Pref->lookup({ id => 1 }), "Get time zone pref";
is $pref->get_id, 1, "Check tz pref ID";
ok @memb =  Bric::Util::Grp::Parts::Member->list
  ({ grp_package => 'Bric::Util::Grp::Pref',
     object      => $pref }),
  "Get one object member";
ok @memb == 1, "Check for one member";
is $memb[0]->get_id, 401, "Check one member ID";
is $memb[0]->get_grp_id, 22, "Check one member grp ID";
is $memb[0]->get_obj_id, 1, "Check one member object ID";

# Now repeat this process using list_ids().
ok @memb = Bric::Util::Grp::Parts::Member->list_ids
  ({ grp_package    => 'Bric::Util::Grp::Pref',
     object_package => 'Bric::Util::Pref',
     object_id      => 1}),
  "Get one member ID";
ok @memb == 1, "Check for one member ID";
is $memb[0], 401, "Check one member ID ID";

ok @memb = Bric::Util::Grp::Parts::Member->list_ids
  ({ grp_package => 'Bric::Util::Grp::Pref',
     object      => $pref }),
  "Get one object member ID";
ok @memb == 1, "Check for one member ID";
is $memb[0], 401, "Check one member ID ID";

# Now it's time to try the href() method. This method works differently than
# the usual one in other classes, in that it has a hashref of hashrefs.
ok my $memb_href = Bric::Util::Grp::Parts::Member->href
  ({ grp_package => 'Bric::Util::Grp::Pref' }), "Get all members";
ok $memb_href->{'Bric::Util::Pref'}{401}, "Hashref memb 401 exists";
ok $memb_href->{'Bric::Util::Pref'}{402}, "Hashref memb 402 exists";

# Now just grab one!
ok $memb_href = Bric::Util::Grp::Parts::Member->href
  ({ grp_package => 'Bric::Util::Grp::Pref',
     object      => $pref }),
  "Get one href object member";
ok $memb_href->{'Bric::Util::Pref'}{401}, "Hashref memb 401 exists";
ok ! $memb_href->{'Bric::Util::Pref'}{402}, "Hashref memb 402 don't exist";

