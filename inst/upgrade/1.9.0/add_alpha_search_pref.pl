#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if fetch_sql "SELECT 1 FROM pref WHERE id = 17";

do_sql

  "INSERT INTO pref (id, name, description, value, def, manual, opt_type, can_be_overridden)
   VALUES (17, 'Show Alpha Search', 'Show links to filter search results by the first letter.', '0', '0', 0, 'select', 0)",

  "INSERT INTO member (id, grp__id, class__id, active)
   VALUES (903, 22, 48, 1)",

  "INSERT INTO pref_member (id, object_id, member__id)
   VALUES (17, 17, 903)",

  "INSERT INTO pref_opt (pref__id, value, description)
   VALUES (17, '0', 'Off')",

  "INSERT INTO pref_opt (pref__id, value, description)
   VALUES (17, '1', 'On')",

  ;

