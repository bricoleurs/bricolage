#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

do_sql
  "UPDATE grp SET description = 'All preferences in the system.' WHERE id = 22",
  ;

  