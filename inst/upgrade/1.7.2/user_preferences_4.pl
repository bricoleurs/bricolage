#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);
use Bric::Config;

# No harm repeating this

do_sql
q/
ALTER TABLE pref ALTER COLUMN can_be_overridden SET DEFAULT 0
/;
