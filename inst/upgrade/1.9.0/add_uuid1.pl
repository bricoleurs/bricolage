#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if test_column 'story', 'uuid';

do_sql
  # Add the uuid column.
  qq{ALTER TABLE story
     ADD COLUMN  uuid TEXT},
  qq{ALTER TABLE media
     ADD COLUMN  uuid TEXT},
;
