#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use Bric::Config qw(MASON_COMP_ROOT);
use Bric::Util::Trans::FS;

# Delete defunct directories.
my $fs = Bric::Util::Trans::FS->new;
for my $dirs (
    [qw(admin profile element_data)],
    [qw(admin profile element_type_data)],
    [qw(admin profile element)],
    [qw(admin manager element)],
    [qw(widgets element_data)]
) {
    $fs->del( $fs->cat_dir( MASON_COMP_ROOT->[0][1], @$dirs ) );
}


