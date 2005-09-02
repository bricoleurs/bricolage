#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade;
use File::Find;
use Bric::Config qw(MASON_COMP_ROOT);
use Bric::Util::Trans::FS;

my $fs = Bric::Util::Trans::FS->new;

find(\&rm_super_bulk, MASON_COMP_ROOT->[0][1]);

sub rm_super_bulk {
    return unless $_ eq 'edit_super_bulk.html';
    print "Deleting $File::Find::name\n";
    $fs->del($File::Find::name);
}

__END__
