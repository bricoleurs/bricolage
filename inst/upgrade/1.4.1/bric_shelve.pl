#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

# This is really simple, and shouldn't hurt anything.
for (qw(story media formatting)) {
    do_sql
      # Set workflow ID to null for deactivated assets.
      "UPDATE $_ SET workflow__id = NULL where active = 0",

      # Delete desk asset grp membership for deactivated assets.
      qq{DELETE FROM member
         WHERE  id IN (
                  SELECT member__id
                  FROM   ${_}_member
                  WHERE  object_id IN (
                           SELECT id
                           FROM   $_
                           WHERE  active = 0
                         )
                )
                AND grp__id IN (
                  SELECT id
                  FROM   grp
                  WHERE  name = 'Desk Assets'
                )
      };
}
