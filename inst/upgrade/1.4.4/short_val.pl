#!/usr/bin/perl -w
# Change short_val field from varchar to text in story_data_tile

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

# We're changing the value column from VARCHAR to TEXT. With TEXT, the value
# of atttypmod is -1.
exit if fetch_sql(q{
    SELECT atttypmod
    FROM   pg_attribute, pg_class
    WHERE  pg_class.oid = pg_attribute.attrelid
           AND pg_class.relname = 'story_data_tile'
           AND pg_attribute.attname = 'short_val'
           AND pg_attribute.atttypmod = -1;
});

do_sql(q{ALTER TABLE story_data_tile RENAME short_val to __short_val_old__},
       q{ALTER TABLE story_data_tile ADD column short_val text},
       q{UPDATE story_data_tile SET short_val = __short_val_old__});
