#!/usr/bin/perl -w
# Make it possible to get the desk_id of an asset object much more quickly

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

foreach (qw(story formatting media)) {
    next if fetch_sql(q{SELECT 1 FROM $_ WHERE desk__id IS NULL OR desk__id IS NOT NULL});
    do_sql
      qq{ALTER TABLE $_ ADD COLUMN desk__id NUMERIC(10,0)},
      qq{
        UPDATE $_
        SET desk__id = to_number(asv.short_val, 9999999999)
        FROM    attr_${_}_val asv, attr_$_ a
        WHERE   asv.id = (
                          SELECT max(id)
                          FROM   attr_${_}_val asv
                          WHERE  asv.object__id = $_.id
                       )
        AND     a.id = asv.attr__id
        AND     a.subsys = 'deskstamps'
        AND     $_.workflow__id IS NOT NULL
      },
      qq{CREATE INDEX fdx_${_}__desk__id ON $_(desk__id)}
}

