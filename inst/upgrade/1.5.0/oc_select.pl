#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

exit if test_column 'element__output_channel', 'enabled';

do_sql
  # Create the new column.
  q{ALTER TABLE element__output_channel ADD COLUMN enabled NUMERIC(1,0)},

  # Set its values.
  q{UPDATE element__output_channel SET enabled = 1},

  # Add its constraints.
  q{ALTER TABLE element__output_channel
      ADD CONSTRAINT ck_at__oc__enabled_null
      CHECK (enabled is NOT NULL)},
  q{ALTER TABLE element__output_channel
      ALTER COLUMN enabled SET DEFAULT 1},
  q{ALTER TABLE element__output_channel
      ADD CONSTRAINT ck_at__oc__enabled
      CHECK (enabled IN (0,1))},
  ;
