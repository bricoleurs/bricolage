#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade;
use Bric::Config qw(BURN_DATA_ROOT);
use Bric::Util::Trans::FS;

my $fs = Bric::Util::Trans::FS->new;
$fs->del($fs->cat_dir(BURN_DATA_ROOT, 'data', 'obj'));
