package Bric::Util::Grp::Parts::Member::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

# Register this class for testing.
BEGIN { __PACKAGE__->test_class }

##############################################################################
# Test class loading.
##############################################################################
sub test_load : Test(1) {
    use_ok('Bric::Util::Grp::Parts::Member');
}


__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 31;

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
ok $memb_href->{1}, "Hashref memb obj 1 exists";
ok $memb_href->{2}, "Hashref memb obj 2 exists";

# Now just grab one!
ok $memb_href = Bric::Util::Grp::Parts::Member->href
  ({ grp_package => 'Bric::Util::Grp::Pref',
     object      => $pref }),
  "Get one href object member";
ok $memb_href->{1}, "Hashref memb obj 1 exists again";
ok ! $memb_href->{2}, "Hashref memb 2 doesn't exist";
