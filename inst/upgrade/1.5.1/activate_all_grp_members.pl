#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

# Make sure that the members of the "All %" groups are always active.
do_sql
  "UPDATE member
   SET    active = 1
   WHERE  grp__id IN (1, 2, 3, 4, 5, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31,
                      32, 33, 34, 35, 41, 43, 45)";

# Update group memberships of all active organizations and sources.
foreach my $table (qw(org source)) {
    do_sql
      "UPDATE member
       SET    active = 1
       WHERE  grp__id <> 5
              AND id IN (
                  SELECT member__id
                  FROM   ${table}_member
                  WHERE  object_id IN (
                      SELECT id
                      FROM   $table
                      WHERE  active = 1
                  )
              )";
}

