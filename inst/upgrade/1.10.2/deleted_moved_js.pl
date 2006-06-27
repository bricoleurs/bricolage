#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use Bric::Config qw(MASON_COMP_ROOT);
use Bric::Util::Trans::FS;

my $fs = Bric::Util::Trans::FS->new;

$fs->del($_) for glob $fs->cat_file(
    MASON_COMP_ROOT->[0][1],
    qw(media js *_messages.js)
);
