#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# If this fails, then the correct constraints are in place.
exit if fetch_sql "SELECT pref__id FROM pref_opt WHERE pref__id = 15 AND value = 'ja'";

do_sql
  "INSERT INTO pref_opt (pref__id, value, description)
   VALUES (15, 'ja', 'ja')";
