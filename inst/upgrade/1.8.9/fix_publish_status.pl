#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if test_constraint 'story', 'ck_story__publish_status';

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

        # We don't know if it has been published since the first
        # publish date, so just go with that.
        qq{UPDATE $thing
           SET    publish_date = first_publish_date
           WHERE  publish_date IS NULL
                  AND first_publish_date IS NOT NULL
        },

        # And the reverse.
        qq{UPDATE $thing
           SET    first_publish_date = publish_date
           WHERE  first_publish_date IS NULL
                  AND publish_date IS NOT NULL
        },

       # If there's a publish date, it was published, so
       # set status and version if they're unset
        qq{UPDATE $thing
           SET    publish_status = '1',
                  published_version = current_version
           WHERE  publish_status = '0'
                  AND published_version IS NULL
                  AND publish_date IS NOT NULL
        },

        # Remove the publish_status when there are no publish dates.
        qq{UPDATE $thing
           SET    publish_status = '0'
           WHERE  publish_date IS NULL
        },

        # Update the published_version.
        qq{UPDATE $thing
           SET    published_version = current_version,
                  publish_status = 1
           WHERE  published_version IS NULL
                  AND current_version IS NOT NULL
                  AND publish_status = 0
                  AND publish_date IS NOT NULL
                  AND first_publish_date IS NOT NULL
        },
    ;
}

__END__
