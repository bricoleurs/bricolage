#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# If this fails, then the correct constraints are in place.
exit if test_constraint 'workflow', 'ck_workflow__type';

do_sql
  "ALTER TABLE workflow
   ADD CONSTRAINT ck_workflow__type
   CHECK (type IN (1,2,3))";
