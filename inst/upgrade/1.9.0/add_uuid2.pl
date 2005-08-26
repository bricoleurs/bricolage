#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);
use Data::UUID;

exit if fetch_sql "SELECT 1 FROM story WHERE uuid IS NOT NULL LIMIT 1";

my $ug = Data::UUID->new;

for my $table (qw(story media)) {
    my $sel = prepare("SELECT id FROM $table");
    my $upd = prepare("UPDATE $table SET uuid = ? WHERE id = ?");
    execute($sel);
    bind_columns($sel, \my $id);
    while (fetch($sel)) {
        execute($upd, $ug->create_str, $id);
    }

    # Add the indices and constraints.
    do_sql
      qq{CREATE UNIQUE INDEX idx_$table\__uuid ON $table(uuid)},
        # Make sure it can never be null.
      qq{ALTER TABLE $table
         ALTER COLUMN uuid SET NOT NULL},
#     qq{ALTER TABLE    $table
#        ADD CONSTRAINT ck_$table\__uuid__null CHECK (uuid IS NOT NULL)},
    ;
}
