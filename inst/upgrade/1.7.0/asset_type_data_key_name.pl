#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

# Exit if these changes have already been made.
exit if test_sql "SELECT 1 WHERE EXISTS (SELECT key_name FROM at_data)";

do_sql
  # Rename the column.
  q/ALTER TABLE at_data RENAME name TO key_name/,
  q/UPDATE at_data
    SET    key_name = TRANSLATE(LOWER(key_name), ' ', '_')/
  ;

__END__

