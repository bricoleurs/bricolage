#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Biz::Asset::Business::Parts::Tile::Data;
use Bric::Util::DBI qw(:all);
use Bric::Util::Time qw(:all);

exit if $Bric::Biz::Asset::Business::Parts::Tile::Data::VERSION > 1.7;

foreach my $type (qw(story media)) {
    my $sel = prepare(qq{
        SELECT id, date_val
        FROM   ${type}_data_tile
        WHERE  date_val IS NOT NULL
    });

    my $upd = prepare(qq{
        UPDATE ${type}_data_tile
        SET    date_val = ?
        WHERE  id = ?
    });

    my ($id, $date);
    execute($sel);
    bind_columns($sel, \$id, \$date);
    while (fetch($sel)) {
        execute($upd, db_date($date), $id);
    }
}

