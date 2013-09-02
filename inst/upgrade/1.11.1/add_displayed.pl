#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

unless (test_column 'element_type', 'displayed') {
    do_sql q{
        ALTER TABLE element_type
        ADD COLUMN displayed BOOLEAN NOT NULL DEFAULT FALSE
    };
}

for my $doc (qw(story media)) {
    next if test_column "$doc\_element", 'displayed';
    do_sql qq{
        ALTER TABLE $doc\_element
        ADD COLUMN displayed BOOLEAN NOT NULL DEFAULT FALSE
    };
}
