#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if fetch_sql "SELECT 1 FROM pref_opt WHERE value = 'zh_cn'";


do_sql
  "INSERT INTO pref_opt (pref__id, value, description)
   VALUES (15, 'zh_cn', 'zh_cn')",

  "INSERT INTO pref_opt (pref__id, value, description)
   VALUES (15, 'zh_hk', 'zh_hk')",

  "INSERT INTO pref_opt (pref__id, value, description)
   VALUES (15, 'bo', 'bo')",

  "INSERT INTO pref_opt (pref__id, value, description)
   VALUES (15, 'km', 'km')",

  "INSERT INTO pref_opt (pref__id, value, description)
   VALUES (15, 'ko_ko', 'ko_ko')",

  "INSERT INTO pref_opt (pref__id, value, description)
   VALUES (15, 'lo', 'lo')",

  "INSERT INTO pref_opt (pref__id, value, description)
   VALUES (15, 'my', 'my')",

  "INSERT INTO pref_opt (pref__id, value, description)
   VALUES (15, 'ug', 'ug')",

  "INSERT INTO pref_opt (pref__id, value, description)
   VALUES (15, 'vi_vn', 'vi_vn')",
  ;
