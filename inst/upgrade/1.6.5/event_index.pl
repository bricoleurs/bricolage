#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

# check if we're already upgraded.
exit if fetch_sql(q{
    SELECT 1
    FROM   pg_class
    WHERE  relname = 'idx_event__obj_id'
});

do_sql 'CREATE INDEX idx_event__obj_id ON event(obj_id)';
