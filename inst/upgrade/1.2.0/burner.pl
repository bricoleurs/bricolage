#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

# Check to see if we've run this before.
exit if test_sql('SELECT burner FROM element');

# Now update it all.
my @sql = (
    'ALTER TABLE element ADD COLUMN burner NUMERIC(2,0) NOT NULL',
    'ALTER TABLE element ALTER burner SET DEFAULT 1',
    'UPDATE element SET burner = 1',
);
do_sql(@sql);
