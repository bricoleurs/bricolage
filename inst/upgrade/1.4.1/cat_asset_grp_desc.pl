#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

# This is really simple, and won't hurt anything.
my $sel = prepare("SELECT name, asset_grp_id FROM category");
my $upd = prepare("UPDATE grp SET description = ? WHERE id = ?");
my ($name, $agid);
execute($sel);
bind_columns($sel, \$name, \$agid);
while (fetch($sel)) {
    execute($upd, $name, $agid);
}
