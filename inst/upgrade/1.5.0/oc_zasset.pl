#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

exit if test_sql(qq{SELECT primary_oc__id FROM story_instance});

foreach my $at (qw(story media)) {
    do_sql
      # Create the new column.
      "ALTER TABLE ${at}_instance ADD COLUMN primary_oc__id NUMERIC(10,0)"
    ;

    my $sel = prepare(qq{
        SELECT s.id, e.primary_oc__id
        FROM   ${at} s, element e
        WHERE  s.element__id = e.id
        ORDER BY s.id
    });

    my $upd = prepare(qq{
        UPDATE ${at}_instance
        SET    primary_oc__id = ?
        WHERE  ${at}__id = ?
    });

    execute($sel);
    my ($sid, $ocid);
    bind_columns($sel, \$sid, \$ocid);
    while (fetch($sel)) {
        execute($upd, $ocid, $sid);
    }

    do_sql
      # Add constraints.
      "ALTER TABLE ${at}_instance
       ADD CONSTRAINT ck_${at}_instance_prim_oc_null
       CHECK (primary_oc__id is NOT NULL)",

      "ALTER TABLE ${at}_instance
       ADD CONSTRAINT fk_primary_oc__${at}_instance FOREIGN KEY (primary_oc__id)
           REFERENCES output_channel(id) ON DELETE SET NULL",

      # Add index.
      "CREATE INDEX fdx_primary_oc__${at}_instance
       ON     ${at}_instance(primary_oc__id)"

    ;

}

