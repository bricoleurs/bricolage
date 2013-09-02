#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

for my $doc (qw(story media)) {
    # Skip it if the cover_date column is already NOT NULL.
    next if test_column "$doc\_instance", 'cover_date', undef, 1;

    my $default = 'CURRENT_TIMESTAMP';

    if (Bric::Config::DBD_TYPE eq 'Pg') {
        do_sql qq{
            UPDATE $doc\_instance
               SET cover_date = COALESCE( first_publish_date, publish_date, $default)
              FROM $doc
             WHERE $doc.id = $doc\_instance.$doc\__id
               AND cover_date IS NULL
        },
        qq{
            ALTER TABLE $doc\_instance
            ALTER COLUMN cover_date SET DEFAULT $default
        },
        qq{
            ALTER TABLE $doc\_instance
            ALTER COLUMN cover_date SET NOT NULL
        };
    } elsif (Bric::Config::DBD_TYPE eq 'mysql') {
        do_sql qq{
            UPDATE $doc\_instance, $doc
               SET cover_date = COALESCE( first_publish_date, publish_date, $default)
             WHERE $doc.id = $doc\_instance.$doc\__id
               AND cover_date IS NULL
        },
        # Fuck you, MySQL. http://bugs.mysql.com/bug.php?id=31452
        qq{
            ALTER TABLE $doc\_instance
            CHANGE cover_date cover_date TIMESTAMP NOT NULL DEFAULT $default
        };
    } else {
        die Bric::Config::DBD_TYPE . ' is not a supported database';
    }
}
