#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

# Looks for stories where the published version is greater than the current
# version and sets the published version to the current version if the story
# has been published, or to NULL if the story has not been published.

exit unless fetch_sql "
    SELECT 1
    FROM story
    WHERE published_version > current_version
    LIMIT 1
";

update_all();

sub update_all {
    my $find_mismatch = prepare("
        SELECT id, current_version
        FROM story
        WHERE published_version > current_version
    ");

    my $find_publish_event = prepare("
        SELECT 1
        FROM event e, event_type et
        WHERE et.key_name = 'story_publish'
        AND e.event_type__id = et.id
        AND e.obj_id = ?
        LIMIT 1
    ");

    my $update_story = prepare("
        UPDATE story
        SET    published_version = ?
        WHERE id = ?
    ");

    my ($id, $current_version);
    execute($find_mismatch);
    bind_columns($find_mismatch, \$id, \$current_version);
    while (fetch($find_mismatch)) {
        # XXX Using the current version, even though it may not actually
        # be the published version. It probably won't be set, anyway,
        # because if a story has been published, then the published_version
        # would have been reset to the correct value and the high published
        # version disposed of.
        my $new_value = row_array($find_publish_event, $id)
          ? $current_version
          : undef;
        execute($update_story, $new_value, $id);
        $find_publish_event->finish;
    }
}

__END__

