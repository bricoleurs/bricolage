#!/usr/bin/perl -w
# Change value field from varchar to text in attr_at_data_meta

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
           AND pg_class.relname = 'attr_at_data_meta'
           AND pg_attribute.attname = 'value'
           AND pg_attribute.atttypmod = -1;
});

do_sql(q{ALTER TABLE attr_at_data_meta RENAME value to __value_old__},
       q{ALTER TABLE attr_at_data_meta ADD column value text},
       q{UPDATE attr_at_data_meta SET value = __value_old__});
