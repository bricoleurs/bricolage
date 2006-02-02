#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# Skip it for later versions of Bricolage.
exit unless test_constraint 'story', 'ck_story__publish_status';

# Later versions will have booleans instead of NUMERIC.
my $bool = test_column('story', 'publish_status', undef, undef, 'boolean');

for my $thing (qw(story media)) {
    do_sql
        qq{ALTER TABLE $thing DROP CONSTRAINT ck_$thing\__publish_status},

        ($bool
         ?  qq{ALTER TABLE $thing
               ADD CONSTRAINT ck_$thing\__publish_status CHECK (
                   (
                       publish_status = FALSE
                       AND publish_date IS NULL
                       AND first_publish_date IS NULL
                   )
                   OR (
                       publish_status = TRUE
                       AND publish_date IS NOT NULL
                       AND first_publish_date IS NOT NULL
                   )
               )
            }
         :  qq{ALTER TABLE $thing
               ADD CONSTRAINT ck_$thing\__publish_status CHECK (
                   publish_status IN (0, 1)
                   AND (
                       (
                           publish_status = 0
                           AND publish_date IS NULL
                           AND first_publish_date IS NULL
                       )
                       OR (
                           publish_status = 1
                           AND publish_date IS NOT NULL
                           AND first_publish_date IS NOT NULL
                       )
                   )
               )
            }
        )
    ;
}

__END__
