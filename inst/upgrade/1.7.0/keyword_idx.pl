#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

exit unless test_index 'udx_keyword__name';

do_sql "DROP INDEX idx_keyword__name",
  "CREATE UNIQUE INDEX udx_keyword__name ON keyword(LOWER(name))";

__END__
