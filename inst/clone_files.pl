#!/usr/bin/perl -w

=head1 Name

clone.pl - installation script to copy files for clone distributions

=head1 Description

This script is called by "make clone" to copy files from the target
installation into the dist/ directory for cloning.

=head1 Author

Sam Tregar <stregar@about-inc.com>

=head1 See Also

L<Bric::Admin>

=cut

use strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use Bric::Inst qw(:all);
use File::Spec::Functions qw(:ALL);
use File::Path qw(mkpath);

our ($CONFIG, $CLONE);
do "./config.db" or die "Failed to read config.db : $!";
do "./clone.db" or die "Failed to read clone.db : $!";

our $HOT_COPY;
$HOT_COPY = 1 if $ARGV[0] and $ARGV[0] eq 'HOT_COPY';

print "\n\n==> Cloning Bricolage Files <==\n\n";

# copy comp, dist and conf from target
system(($HOT_COPY ? "cp -al" : "cp -pR") . " $CONFIG->{MASON_COMP_ROOT} dist");
system(($HOT_COPY ? "cp -al" : "cp -pR") . " $CONFIG->{MASON_DATA_ROOT} dist");
system("cp -pR $CLONE->{CONFIG_DIR} dist");

# Copy lib from target.
my $libdir = catdir curdir, 'dist', 'lib';
mkpath $libdir;
system("cp -pR $CONFIG->{MODULE_DIR}/Bric* $libdir");
# Copy the Makefile.PL from source.
my $makefile = catfile curdir, 'lib', 'Makefile.PL';
system("cp -pR $makefile $libdir");

# Copy bin from target.
my $bindir = catdir curdir, 'dist', 'bin';
mkpath $bindir;
system("cp -pR $CONFIG->{BIN_DIR}/bric_* $bindir");
# Copy the Makefile.PL from source.
$makefile = catfile curdir, 'bin', 'Makefile.PL';
system("cp -pR $makefile $bindir");

# remove conf/install.db
unlink("dist/conf/install.db");

# copy everything else from source
opendir(CUR, '.') or die $!;
my %exclude = map { $_ => 1 } qw(. .. dist comp data conf bin lib);
foreach my $d (readdir(CUR))  {
    next if $exclude{$d} or $d =~ /[.](?:db|sql)$/ or $d =~ /^bricolage-/;
    system("cp -pR $d dist");
}
close(CUR);

# Set owner and group to the current owner and group.
#my $uid = $>;
my $uid = 0;
#(my $gid = $) =~ s/\s.*//);
my $gid = 0;
system 'chown', '-R', "$uid:$gid", 'dist';

print "\n\n==> Finished Cloning Bricolage Files <==\n\n";
