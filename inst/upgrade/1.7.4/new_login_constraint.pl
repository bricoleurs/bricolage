#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# Make sure that we haven't run this update before.
exit unless test_constraint 'usr', 'ck_usr__login';

do_sql
  'ALTER TABLE usr DROP CONSTRAINT ck_usr__login',
  'DROP FUNCTION login_avail(varchar, numeric, numeric)',
  'CREATE UNIQUE INDEX udx_usr__login ON usr(LOWER(login)) WHERE active = 1'
  ;

