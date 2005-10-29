#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

for my $thing (qw(story media category)) {
    next unless test_primary_key "$thing\_keyword", "$thing\_keyword_pkey";
    do_sql
        "ALTER TABLE $thing\_keyword DROP CONSTRAINT $thing\_keyword_pkey",
        "ALTER TABLE $thing\_keyword ADD CONSTRAINT pk_$thing\_keyword
         PRIMARY KEY ($thing\_id, keyword_id)",
    ;
}

__END__
