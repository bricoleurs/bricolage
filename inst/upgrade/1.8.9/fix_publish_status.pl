#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

for my $thing (qw(story media)) {
    do_sql
        qq{UPDATE $thing
           SET    publish_status = '1'
           WHERE  published_version IS NOT NULL
                  AND publish_status = '0'
        },

        # We have no idea what version was actually published, so
        # current_version is the best we can do. :-(
        qq{UPDATE $thing
           SET    published_version = current_version
           WHERE  published_version IS NULL
                  AND publish_status = '1'
        },
    ;
}

__END__
