#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

exit if test_column 'formatting', 'tplate_type';

do_sql
  # Create the new column.
  q{ALTER TABLE formatting ADD COLUMN tplate_type NUMERIC(1,0)},

  # Set its values.
  q{UPDATE formatting SET tplate_type = 1 WHERE file_name LIKE '%.mc'},
  q{UPDATE formatting SET tplate_type = 1 WHERE file_name LIKE '%.tmpl'},
  q{UPDATE formatting SET tplate_type = 1 WHERE file_name LIKE '%.pl'},
  q{UPDATE formatting SET tplate_type = 2 WHERE tplate_type IS NULL},

  # Add its constraints.
  q{ALTER TABLE formatting
      ALTER COLUMN tplate_type SET DEFAULT 1},
  q{ALTER TABLE formatting
      ADD CONSTRAINT ck_formatting__tplate_type_null
      CHECK (tplate_type is NOT NULL)},
  q{ALTER TABLE formatting
      ADD CONSTRAINT ck_formatting__tplate_type
      CHECK (tplate_type IN (1, 2, 3))},

  # Create an index to ensure unique templates.
  q{CREATE UNIQUE INDEX udx_formatting__file_name__oc
      ON formatting(file_name, output_channel__id)}
  ;
