#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit unless test_column 'story', 'cover_date';

for my $table (qw(story media)) {
    do_sql
        qq{ALTER TABLE $table\_instance
           ADD COLUMN cover_date timestamp,
        },

        qq{UPDATE $table\_instance
           SET    cover_date  = $table.cover_date,
           FROM   $table
           WHERE  $table.id = $table\_instance.$table\__id
        },

        qq{ALTER TABLE $table
           DROP COLUMN cover_date,
        },

        qq{CREATE INDEX idx_$table\_instance__cover_date
           ON $table\_instance(cover_date)
        },
    ;
}
;

1;
__END__
