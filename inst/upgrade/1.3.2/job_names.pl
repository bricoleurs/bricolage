#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

=pod

=begin comment

This script updates a few tables where the column for the job name was too
small (32 characters rather than 256). Due to the limitations of PostgreSQL
this is not nearly as easy as it should be. I could use the temp table
switch technique here:

      http://techdocs.postgresql.org/techdocs/updatingcolumns.php

Except that these tables have referential constraints on them from other tables.
The best I could come up with is to rename the old column and move the data into
a new column of the correct type and old name.

This leaves an extra column in the database, but it won't really hurt much.
Maybe someday PostgreSQL will have a DROP COLUMN command, and we can do away
with the column.

=end comment

=cut

# This is PostgreSQL-specific, but that shouldn't matter, since PostgreSQL is
# the only supported database at this time, so no other database should need the
# patch.
exit if fetch_sql(qq{
    SELECT atttypmod
    FROM   pg_attribute, pg_class
    WHERE  pg_class.oid = pg_attribute.attrelid
           AND pg_class.relname = 'job'
           AND pg_attribute.attname = 'name'
           AND pg_attribute.atttypmod >= 256;
});

do_sql(
       'DROP INDEX idx_job__name',
       'ALTER TABLE job RENAME name TO __name__old__',
       'ALTER TABLE job ADD name VARCHAR(256)',
       'UPDATE job SET name = __name__old__',
       'CREATE INDEX idx_job__name ON job(LOWER(name))'
);

__END__
