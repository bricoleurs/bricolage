#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if fetch_sql "SELECT 1 FROM pref_opt WHERE value = '%Y-%m-%d %T.%3N'";

do_sql

  "INSERT INTO pref_opt (pref__id, value, description)
   VALUES (5, '%Y-%m-%d %T.%3N', 'ISO-8601 Compliant with miliseconds (CCYY-MM-DD hh:mm:ss.000)')",

  "INSERT INTO pref_opt (pref__id, value, description)
   VALUES (5, '%Y-%m-%d %T.%6N', 'ISO-8601 Compliant with microseconds (CCYY-MM-DD hh:mm:ss.000000)')",

  "INSERT INTO pref_opt (pref__id, value, description)
   VALUES (5, '%Y-%m-%dT%T.%3N', 'ISO-8601 Strict with miliseconds (CCYY-MM-DDThh:mm:ss.000)')",

  "INSERT INTO pref_opt (pref__id, value, description)
   VALUES (5, '%Y-%m-%dT%T.%6N', 'ISO-8601 Strict with microseconds (CCYY-MM-DDThh:mm:ss.000000)')",
  ;

