#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if fetch_sql q{SELECT 1 FROM pref_opt WHERE value = 'cp1252'};

do_sql
  q{INSERT INTO pref_opt (pref__id, value, description)
    VALUES ('14', 'cp1250', 'Windows Central European (CP1250)')},

  q{INSERT INTO pref_opt (pref__id, value, description)
    VALUES ('14', 'cp1251', 'Windows Cyrillic (CP1251)')},

  q{INSERT INTO pref_opt (pref__id, value, description)
    VALUES ('14', 'cp1252', 'Windows Western (CP1252)')},

  q{INSERT INTO pref_opt (pref__id, value, description)
    VALUES ('14', 'cp1253', 'Windows Greek (CP1253)')},

  q{INSERT INTO pref_opt (pref__id, value, description)
    VALUES ('14', 'cp1254', 'Windows Turkish (CP1254)')},

  q{INSERT INTO pref_opt (pref__id, value, description)
    VALUES ('14', 'cp1255', 'Windows Hebrew (CP1255)')},

  q{INSERT INTO pref_opt (pref__id, value, description)
    VALUES ('14', 'cp1256', 'Windows Arabic (CP1256)')},

  q{INSERT INTO pref_opt (pref__id, value, description)
    VALUES ('14', 'cp1258', 'Windows Vietnamese (CP1258)')},
;
