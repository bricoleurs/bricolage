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
      "ALTER TABLE ${at}_instance ADD COLUMN primary_oc__id NUMERIC(1,0)",

      # Set its value
      "UPDATE ${at}_instance
       SET    primary_oc__id = element.primary_oc__id
       FROM   element, ${at}
       WHERE  ${at}.id = ${at}_instance.${at}__id
              AND ${at}.element__id = element.id",

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

