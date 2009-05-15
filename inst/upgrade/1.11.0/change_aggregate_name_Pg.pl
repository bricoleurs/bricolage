#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if test_aggregate('group_concat');

do_sql

  'DROP AGGREGATE id_list (INTEGER)',

  "CREATE AGGREGATE group_concat (
    SFUNC      = append_id,
    BASETYPE = INTEGER,
    STYPE    = TEXT,
    INITCOND = ''
   )
   ",

  ;

