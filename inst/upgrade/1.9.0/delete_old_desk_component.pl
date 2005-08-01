#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(updir catdir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade;
use Bric::Config qw(MASON_COMP_ROOT);

# Delete legacy non-XHTML desk component.
my $file = catdir MASON_COMP_ROOT, "widgets", "desk", "desk_item_old.html";
unlink($file) if -e $file;

__END__
