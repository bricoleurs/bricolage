#!/usr/bin/perl -w

=head1 NAME

clone.pl - installation script to copy files for clone distributions

=head1 VERSION

$Revision: 1.5 $

=head1 DATE

$Date: 2004-02-21 19:40:30 $

=head1 DESCRIPTION

This script is called by "make clone" to copy files from the target
installation into the dist/ directory for cloning.

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

=head1 SEE ALSO

L<Bric::Admin>

=cut

use strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use Bric::Inst qw(:all);
use File::Spec::Functions qw(:ALL);

our ($CONFIG, $CLONE);
do "./config.db" or die "Failed to read config.db : $!";
do "./clone.db" or die "Failed to read clone.db : $!";

print "\n\n==> Cloning Bricolage Files <==\n\n";

# copy comp, dist and conf from target
system("cp -pR $CONFIG->{MASON_COMP_ROOT} dist");
system("cp -pR $CONFIG->{MASON_DATA_ROOT} dist");
system("cp -pR $CLONE->{CONFIG_DIR} dist");

# remove conf/install.db
unlink("dist/conf/install.db");

# copy everything else from source
opendir(CUR, '.') or die $!;
foreach my $d (readdir(CUR))  {
    next if $d eq '.' or $d eq '..';
    next if $d =~ /.db$/;
    next if $d eq 'dist' or $d eq 'comp' or $d eq 'data' or $d eq 'conf';
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
