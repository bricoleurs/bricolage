#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

=pod

=begin comment

This script updates a few tables where the column for the element name was too
small (32 characters rather than 64). Due to the limitations of PostgreSQL this
is not nearly as easy as it should be. I could use the temp table switch
technique here:

      http://techdocs.postgresql.org/techdocs/updatingcolumns.php

Except that these tables have referential constraints on them from other tables.
The best I could come up with is to rename the old column and move the data into
a new column of the correct type and old name.

This leaves an extra column in the database, but it won't really hurt much.
Maybe someday PostgreSQL will have a DROP COLUMN command, and we can do away
with the column.

=end comment

=cut

# Exit if the column is already at least 64 characters long.
exit if test_column 'story_container_tile', 'name', 64;

do_sql(
    'DROP INDEX idx_sc_tile__name',
    'ALTER TABLE story_container_tile RENAME name TO __name__old__',
    'ALTER TABLE story_container_tile ADD name VARCHAR(64)',
    'UPDATE story_container_tile SET name = __name__old__',
    'CREATE INDEX idx_sc_tile__name ON story_container_tile(LOWER(name))',

    'DROP INDEX idx_mc_tile__name',
    'ALTER TABLE media_container_tile RENAME name TO __name__old__',
    'ALTER TABLE media_container_tile ADD name VARCHAR(64)',
    'UPDATE media_container_tile SET name = __name__old__',
    'CREATE INDEX idx_mc_tile__name ON media_container_tile(LOWER(name))',

    'DROP INDEX idx_story_data_tile__name',
    'ALTER TABLE story_data_tile RENAME name TO __name__old__',
    'ALTER TABLE story_data_tile ADD name VARCHAR(64)',
    'UPDATE story_data_tile SET name = __name__old__',
    'CREATE INDEX idx_story_data_tile__name ON story_data_tile(LOWER(name))',

    'DROP INDEX idx_media_data_tile__name',
    'ALTER TABLE media_data_tile RENAME name TO __name__old__',
    'ALTER TABLE media_data_tile ADD name VARCHAR(64)',
    'UPDATE media_data_tile SET name = __name__old__',
    'CREATE INDEX idx_media_data_tile__name ON media_data_tile(LOWER(name))'
);

__END__
