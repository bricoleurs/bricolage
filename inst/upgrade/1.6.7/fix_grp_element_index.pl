#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

do_sql
  'DROP INDEX fkx_grp__element',
  'CREATE INDEX fkx_grp__element ON element(at_grp__id)'
  ;

__END__
