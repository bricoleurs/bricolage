#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

# This script removes assets from desks when they're on desks twice.
for (qw(story media formatting)) {

    # Query to collect all the desk group memberships.
    my $sel = prepare(qq{
        SELECT m.id, m.grp__id, i.object_id
        FROM   ${_}_member i,
               member m
        WHERE  m.id = i.member__id
               AND m.grp__id IN (
                   SELECT id
                   FROM   grp
                   WHERE  name = 'Desk Assets'
               )
    });

    execute($sel);
    my ($memid, $grpid, $objid, %map);
    bind_columns($sel, \$memid, \$grpid, \$objid);
    while (fetch($sel)) {
        # Associate each mem ID with the obj ID/grp ID combination.
        push @{$map{$objid}->{$grpid}}, $memid;
    }

    my @delids;
    foreach my $grp (values %map) {
        foreach my $membs (values %$grp) {
            # Pop off one member to leave it in the database.
            pop @$membs;
            # Collect all the other member IDs for deletion. These represent
            # duplicate memberships for one asset on one desk.
            push @delids, @$membs;
        }
    }

    if (@delids) {
        # Turn the IDs into a list and delete them.
        my $delids = join ', ', @delids;
        do_sql "DELETE FROM member WHERE id IN ($delids)";
    }
}
