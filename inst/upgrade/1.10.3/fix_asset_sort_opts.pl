#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if fetch_sql "SELECT 1 FROM pref_opt WHERE pref__id = 13 AND value = 'uri'";

do_sql
    q{UPDATE pref_opt SET value = 'element_type'
      WHERE  pref__id = 13 AND value = 'element'},

    q{UPDATE pref SET value = 'element_type'
      WHERE  id = 13 AND value = 'element'},

    q{INSERT INTO pref_opt (pref__id, value, description)
      VALUES ('13', 'uri', 'URI/File Name')},
