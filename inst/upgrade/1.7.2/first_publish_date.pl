#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if test_column('story', 'first_publish_date');

for my $t (qw(story media)) {
    do_sql
      # Add the new column.
      "ALTER TABLE $t ADD first_publish_date TIMESTAMP",

      # Populate the new column.
      qq{UPDATE $t
         SET    first_publish_date = (
                    SELECT MIN(timestamp)
                    FROM   event, event_type
                    WHERE  obj_id = $t.id
                           AND event.event_type__id = event_type.id
                           AND event_type.key_name = '$t\_publish'
                )},

      # Create all necessary indexes.
      "CREATE INDEX idx_$t\__first_publish_date ON $t(first_publish_date)",
      ( $t eq 'story'
        # Story was missing indexes!
        ? ("CREATE INDEX idx_$t\__publish_date ON $t(publish_date)",
           "CREATE INDEX idx_$t\__cover_date ON $t(cover_date)")
        : ()
      )
    ;
}
