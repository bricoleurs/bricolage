#!/usr/bin/perl -w

=head1 NAME

clone.pl - installation script to copy files for clone distributions

=head1 VERSION

$Revision: 1.1.6.1 $

=head1 DATE

$Date: 2003-06-06 20:15:47 $

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

our $CONFIG;
do "./config.db" or die "Failed to read config.db : $!";

print "\n\n==> Cloning Bricolage Files <==\n\n";

# copy comp, dist and conf from target
system("cp -pR $CONFIG->{MASON_COMP_ROOT} dist");
system("cp -pR $CONFIG->{MASON_DATA_ROOT} dist");
system("cp -pR $CONFIG->{BRICOLAGE_ROOT}/conf dist");

# remove conf/install.db
unlink("dist/conf/install.db");

# copy everything else from source
opendir(CUR, '.') or die $!;
foreach my $d (readdir(CUR))  {
    next if $d eq '.' or $d eq '..';
    next if $d =~ /.db$/;
    next if $d eq 'dist' or $d eq 'comp' or $d eq 'data';
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
