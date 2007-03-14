#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# Later versions will have booleans instead of NUMERIC.
my ($true, $false)
    = test_column('story', 'publish_status', undef, undef, 'boolean')
    ? qw(TRUE FALSE)
    : qw( 1 0 );

for my $thing (qw(story media)) {
    do_sql
        qq{UPDATE $thing
           SET    publish_status = $true
           WHERE  published_version IS NOT NULL
                  AND publish_status = $false
        },

        # We have no idea what version was actually published, so
        # current_version is the best we can do. :-(
        qq{UPDATE $thing
           SET    published_version = current_version
           WHERE  published_version IS NULL
                  AND publish_status = $true
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
           SET    publish_status = $false
           WHERE  publish_date IS NULL
        },

        # Update the published_version.
        qq{UPDATE $thing
           SET    published_version = current_version,
                  publish_status = $true
           WHERE  published_version IS NULL
                  AND current_version IS NOT NULL
                  AND publish_status = $false
                  AND publish_date IS NOT NULL
                  AND first_publish_date IS NOT NULL
        },

        # Try to catch any stragglers.
        qq{UPDATE $thing
           SET    published_version = NULL,
                  publish_status = $false,
                  publish_date = NULL,
                  first_publish_date = NULL
           WHERE  publish_status = $false
                  AND (
                      publish_date IS NOT NULL
                      OR first_publish_date IS NOT NULL
                      OR published_version IS NOT NULL
                  )
        },

        # Try to catch other stragglers.
        qq{UPDATE $thing
           SET    published_version = NULL,
                  publish_status = $false,
                  publish_date = NULL,
                  first_publish_date = NULL
           WHERE  publish_status = $true
                  AND (
                      publish_date IS NULL
                      OR first_publish_date IS NULL
                      OR published_version IS NULL
                  )
        },
    ;
}

__END__
