#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# check if we're already upgraded.
exit if test_index 'idx_job__comp_time__is_null';

do_sql
  'CREATE INDEX idx_job__comp_time__is_null
   ON job(comp_time)
   WHERE comp_time is NULL'
  ;

__END__
