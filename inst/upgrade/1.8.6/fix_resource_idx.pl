#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit unless test_index 'idx_resrouce__mod_time';

do_sql
  "DROP INDEX idx_resrouce__mod_time",
  "CREATE INDEX idx_resource__mod_time ON resource(mod_time)"
  ;
