#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use Bric::Inst qw(:all);

# make sure we're root, otherwise uninformative errors result
unless ($> == 0) {
    print "This process must (usually) be run as root.\n";
    exit 1 unless ask_yesno("Continue as non-root user? [yes] ", 1);
}

