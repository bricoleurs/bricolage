#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# Exit if the column is already NOT NULL.
exit if test_column 'media_instance', 'media_type__id', undef, 1;

do_sql "ALTER TABLE  media_instance
        ALTER COLUMN media_type__id SET NOT NULL
";
