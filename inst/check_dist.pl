#!/usr/bin/perl -w

=head1 Name

check_dist.pl - checks to make sure we're ready for "make dist"

=head1 Description

This script is called by "make dist" to check that everything is as it
should be.

=head1 Author

Sam Tregar <stregar@about-inc.com>

=head1 See Also

L<Bric::Admin>

=cut

use strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use Bric::Inst qw(:all);

my $version = shift;

# check versions.txt
my @versions;
open(VER, "inst/versions.txt") or die "Cannot open inst/versions.txt : $!";
while (<VER>) {
    chomp;
    next if /^#/ or /^\s*$/;
    push @versions, $_;
}
close VER;
hard_fail("You forgot to update inst/version.txt!\n".
      "This version ($version) must be on the last line.\n")
    unless $versions[-1] eq $version;

# make sure README is updated
open(README, "README") or die "Cannot open README : $!";
my $readme = join('', <README>);
hard_fail("You forgot to update README.\n".
      "This version ($version) must appear in the file.\n")
    unless $readme =~ /$version/;

