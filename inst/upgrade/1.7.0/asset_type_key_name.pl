#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

# Just exit if these changes have already been made.
exit if test_sql "SELECT 1 WHERE EXISTS (SELECT key_name FROM element)";


do_sql
  # Add the new column.
  q/ALTER TABLE element ADD key_name VARCHAR(64)/,

  # Populate it with data. I think that this may not be the best approach...
  # What about non-ascii characters?
  q/UPDATE element SET key_name = TRANSLATE(LOWER(name), ' ', '_')/,

  # Add a NOT NULL constraint.
  q{ALTER TABLE element
      ADD CONSTRAINT ck_key_name__null
      CHECK (key_name IS NOT NULL)},

  # Add an index.
  qq{CREATE UNIQUE INDEX udx_element__key_name ON element(LOWER(key_name))},

  # Drop the old index on the name column.
  qq{DROP INDEX udx_element__name}
  ;

__END__
