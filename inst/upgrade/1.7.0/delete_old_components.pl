#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(updir catdir);
use File::Path qw(mkpath rmtree);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade;
use Bric::Config qw(MASON_COMP_ROOT);

# Delete UI components that we no longer use and that could therefore
# cause errors.
for (qw(story media templates)) {
    my $dir = catdir MASON_COMP_ROOT, qw(workflow manager), $_;
    rmtree $dir if -e $dir;
}

__END__
