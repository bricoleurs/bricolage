#!/usr/bin/perl -w
# Make it possible to get the desk_id of an asset object much more quickly

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

foreach my $table (qw(story formatting media)) {
    next if test_sql(qq{SELECT 1 WHERE EXISTS (SELECT desk__id FROM $table)});
    do_sql
      qq{ALTER TABLE $table ADD COLUMN desk__id NUMERIC(10,0)},
      qq{
        UPDATE $table
        SET desk__id = to_number(asv.short_val, 9999999999)
        FROM    attr_${table}_val asv, attr_$table a
        WHERE   asv.id = (
                          SELECT max(id)
                          FROM   attr_${table}_val asv
                          WHERE  asv.object__id = $table.id
                       )
        AND     a.id = asv.attr__id
        AND     a.subsys = 'deskstamps'
        AND     $table.workflow__id IS NOT NULL
      },
      qq{CREATE INDEX fdx_${table}__desk__id ON $table(desk__id)}
}

