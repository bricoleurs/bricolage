#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

# If this fails, then the correct constraints are in place.
exit if test_column 'action', 'active';

do_sql
  # Add the active column.
  qq{ALTER TABLE action
     ADD COLUMN  active NUMERIC(1,0)},

  # Set its default value to 1.
  qq{ALTER TABLE action
     ALTER COLUMN active SET DEFAULT 1},

  # Make sure that it isn't null.
  qq{UPDATE action SET active = 1},

  # Make sure it can never be null.
  qq{ALTER TABLE    action
     ADD CONSTRAINT ck_action__active__null CHECK (active IS NOT NULL)},

  # Constrain its value to 0 and 1.
  qq{ALTER TABLE    action
     ADD CONSTRAINT ck_action__active CHECK (active IN (1,0))},
  ;
