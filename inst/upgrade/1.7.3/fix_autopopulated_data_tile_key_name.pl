#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

# This is to correct the bad key names used for autopopulated media data
# elements, but we'll do story data elements, too, just to be sure.

for my $table (qw(story_data_tile media_data_tile)) {
    my $select = prepare("SELECT DISTINCT name FROM $table");
    my $update = prepare("UPDATE $table SET key_name = ? WHERE name = ?");

    my $name;
    execute($select);
    bind_columns($select, \$name);

    while (fetch($select)) {
        my $key_name = lc($name);
        $key_name =~ y/a-z0-9/_/cs;
        execute($update, $key_name, $name);
    }
}
