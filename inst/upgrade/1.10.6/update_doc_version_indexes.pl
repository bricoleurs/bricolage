#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

for my $doc qw(story media) {
    next if test_index "udx_$doc\__$doc\_instance";
    my $on = DBD_TYPE eq 'mysql' ? " ON $doc\_instance" : '';
    do_sql
        qq{
            CREATE UNIQUE INDEX udx_$doc\__$doc\_instance
                ON $doc\_instance($doc\__id, version, checked_out)
        },
        "DROP INDEX fkx_$doc\__$doc\_instance$on",
    ;
}
