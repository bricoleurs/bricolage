#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

# Just bail if the column already exists.
exit if test_column 'formatting', 'published_version';

do_sql "ALTER TABLE formatting ADD published_version NUMERIC(10,0)";

1;
__END__
