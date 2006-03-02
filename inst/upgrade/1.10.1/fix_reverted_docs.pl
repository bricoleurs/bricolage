#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use Bric::Util::DBI qw(:all);

for my $doc (qw(story media)) {
    my $sel = prepare('
        SELECT object_instance_id
        FROM   story_element
        GROUP BY object_instance_id
        HAVING COUNT(object_instance_id) > 1
    ');

    execute($sel);
    bind_columns($sel, \my $id);

    my $sel_ids = prepare('
        SELECT id
        FROM   story_element
        WHERE  object_instance_id = ?
    ');

    my $del = prepare('
        DELETE FROM story_element
        WHERE  id = ?
    ');

    while (fetch($sel)) {
        my $ids = col_aref($sel_ids, $id);
        $ids = [ sort { $a <=> $b } @$ids ];
        pop @$ids;
        execute($del, $_) for @$ids;
    }
}
