#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

foreach my $col (qw(lname fname mname)) {
    do_sql "DROP INDEX idx_person__$col",
           "CREATE INDEX idx_person__$col ON person(LOWER($col))";
}

__END__
