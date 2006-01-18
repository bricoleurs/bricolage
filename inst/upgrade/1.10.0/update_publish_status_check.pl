#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

for my $thing (qw(story media)) {
    do_sql
        qq{ALTER TABLE $thing DROP CONSTRAINT ck_$thing\__publish_status},

        qq{ALTER TABLE $thing
           ADD CONSTRAINT ck_$thing\__publish_status CHECK (
               (
                   publish_status = '0'
                   AND publish_date IS NULL
                   AND first_publish_date IS NULL
               )
               OR (
                   publish_status = '1'
                   AND publish_date IS NOT NULL
                   AND first_publish_date IS NOT NULL
               )
           )
        },
    ;
}

__END__
