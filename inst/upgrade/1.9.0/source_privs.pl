#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# This ID will either be used by the installer or this upgrade script.
exit if fetch_sql "SELECT 1 FROM grp_priv WHERE id = 59";

# Give All Users READ rights to all sources.
do_sql
  "INSERT INTO grp_priv (id, grp__id, value)
   VALUES('59', '2', '1')",

  "INSERT INTO grp_priv__grp_member (grp_priv__id, grp__id)
  VALUES('59', '5')"
  ;

