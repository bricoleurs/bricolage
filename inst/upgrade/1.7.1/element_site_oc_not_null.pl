#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# Just exit if the column is NOT NULL.
exit if fetch_sql
  "select attnotnull
   FROM   pg_attribute
   WHERE  attname = 'primary_oc__id'
          AND attnotnull = 't'
          AND attrelid in (
            SELECT pg_class.oid
            FROM   pg_class
            WHERE  relkind='r'
                   AND relname='element__site'
          )
  ";


# Make sure that there are no NULLs in the column.
die "Cannot make element__site.primary_oc__id NOT NULL because\n",
  "there are NULL values in it. This is because this there are\n",
  "story type and/or media type elements without a primary output\n",
  "channel associated with one or more sites. Please correct this\n",
  "problem and try again.\n"
  if fetch_sql
  "SELECT 1
   WHERE  EXISTS (
            SELECT 1
            FROM   element__site
            WHERE  primary_oc__id IS NULL
          )
  ";

# Make the column NOT NULL.
if (db_version ge '7.3') {
    # This should work even if the column already is not null.
    do_sql "ALTER TABLE element__site ALTER COLUMN primary_oc__id SET NOT NULL";
} else {
    # This approach may not be safe. If so, we'll have to add the constraint
    # using a CHECK.
    do_sql
      "UPDATE pg_attribute
       SET    attnotnull = 't'
       WHERE  attname = 'primary_oc__id'
               AND attrelid in (
                 SELECT pg_class.oid
                 FROM   pg_class
                 WHERE  relkind='r'
                        AND relname='element__site'
               )
      ";
}

