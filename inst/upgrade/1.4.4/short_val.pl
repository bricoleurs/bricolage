#!/usr/bin/perl -w
# Change short_val field from varchar to text in story_data_tile

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

# We're changing the value column from VARCHAR to TEXT. With TEXT, the value
# of atttypmod is -1, so we can just see if it's greater than that.
exit unless test_column 'story_data_tile', 'short_val', 0;

do_sql(q{ALTER TABLE story_data_tile RENAME short_val to __short_val_old__},
       q{ALTER TABLE story_data_tile ADD column short_val text},
       q{UPDATE story_data_tile SET short_val = __short_val_old__});
