#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

do_sql
  'UPDATE grp
   SET    active = 0
   WHERE  id IN (
            SELECT asset_grp_id
            FROM   category
            WHERE  active = 0
          )
  ';
