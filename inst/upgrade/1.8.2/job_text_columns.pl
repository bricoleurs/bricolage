#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# Exit unless the name column is 256 characters.
exit unless test_column 'job', 'name', 256;

do_sql
  # Create the new name column and copy over the old values.
  q{ALTER TABLE job RENAME name to __name_old__},
  q{ALTER TABLE job ADD column name text},
  q{UPDATE job SET name = __name_old__},

  # Create the new error_message column and copy over the old values.
  q{ALTER TABLE job RENAME error_message to __error_message_old__},
  q{ALTER TABLE job ADD column error_message text},
  q{UPDATE job SET error_message = __error_message_old__},

  # Drop the old columns?
  (db_version() ge '7.3'
     # We can drop the old columns.
     ? ( q{ALTER TABLE job drop __name_old__},
         q{ALTER TABLE job drop __error_message_old__},
       )
     # We can't drop the old columns, so we'll need to delete the old index.
     : ( q{DROP INDEX idx_job__name} )
  ),

  # Index the name new column.
  q{CREATE INDEX idx_job__name ON job(LOWER(name))}
;
