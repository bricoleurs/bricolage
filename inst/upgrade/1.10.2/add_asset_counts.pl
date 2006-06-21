#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if fetch_sql "SELECT 1 FROM pref WHERE id = 18";

do_sql

  "INSERT INTO pref (id, name, description, value, def, manual, opt_type, can_be_overridden)
   VALUES (18, 'Show Desk Asset Counts', 'Show the number of assets on each desk in the navigation.', '0', '0', '0', 'select', '0')",

  "INSERT INTO member (id, grp__id, class__id, active)
   VALUES (904, 22, 48, '1')",

  "INSERT INTO pref_member (id, object_id, member__id)
   VALUES (18, 18, 904)",

  "INSERT INTO pref_opt (pref__id, value, description)
   VALUES (18, '0', 'Off')",

  "INSERT INTO pref_opt (pref__id, value, description)
   VALUES (18, '1', 'On')",

  ;

