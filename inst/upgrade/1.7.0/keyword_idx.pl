#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

exit unless test_sql "DROP INDEX idx_keyword__name";

do_sql "CREATE UNIQUE INDEX udx_keyword__name ON keyword(LOWER(name))";

__END__
