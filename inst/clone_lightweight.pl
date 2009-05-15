#!/usr/bin/perl -w

=head1 Name

clone_lightweight.pl

=head1 Description

This script is called by "make clone" after clone_files.pl to remove all
pre-compiled and locally previewed files from the tree in order to make a
lightweight clone.

=head1 Author

Paul Orrock <paulo@digitalcraftsmen.net>

=head1 See Also

L<Bric::Admin>

=cut

use strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use Bric::Inst qw(:all);
use File::Spec::Functions qw(:ALL);
use File::Path qw(rmtree mkpath);


our ($CONFIG, $CLONE);
do "./config.db" or die "Failed to read config.db : $!";
do "./clone.db" or die "Failed to read clone.db : $!";

print "\n\n==> Removing Files for Lightweight Clone <==\n\n";

# take out everything below the following directories and then remake the dirs
my @dirs = qw(comp/data/preview data/burn/data/obj data/burn/stage
    data/burn/preview data/burn/sandbox data/obj);

foreach my $dir (@dirs) {
    rmtree('dist/' . $dir);
    mkpath('dist/' . $dir);
}

print "\n\n==> Finished Lightweight Clone <==\n\n";
