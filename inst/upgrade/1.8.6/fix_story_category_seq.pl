#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

do_sql
  "ALTER TABLE story__category ALTER COLUMN id DROP DEFAULT",
  "ALTER TABLE story__category ALTER COLUMN id SET DEFAULT NEXTVAL('seq_story__category')",
  ;
