#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

do_sql
  "ALTER TABLE event ALTER COLUMN id DROP DEFAULT",
  "ALTER TABLE event ALTER COLUMN id SET DEFAULT NEXTVAL('seq_event')",
  ;
