#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

# This is really simple, and won't hurt anything.
for (qw(story media formatting)) {
    do_sql "UPDATE $_ SET workflow__id = NULL where active = 0";
}

