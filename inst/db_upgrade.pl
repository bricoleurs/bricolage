#!/usr/bin/perl -w

=head1 NAME

db_upgrade.pl - installation script to run db upgrade scripts

=head1 VERSION

$Revision: 1.1.6.1 $

=head1 DATE

$Date: 2003-05-01 23:43:59 $

=head1 DESCRIPTION

This script is called by "make upgrade" to run the database upgrade
scripts.  Uses upgrade.db to determine which ones to run.

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
use Data::Dumper;

our $UPGRADE;
do "./upgrade.db" or die "Failed to read upgrade.db : $!";
our $CONFIG;
do "./config.db" or die "Failed to read config.db : $!";
our $PG;
do './postgres.db' or die "Failed to read postgres.db : $!";

print "\n\n==> Starting Database Upgrade <==\n\n";

# setup environment to ensure scripts run correctly
$ENV{BRICOLAGE_ROOT} = $UPGRADE->{BRICOLAGE_ROOT};

# run the upgrade scripts
foreach my $v (@{$UPGRADE->{TODO}}) {
    my $dir = catdir("inst", "upgrade", $v);
    print "Looking for scripts for $v in $dir\n";
    next unless -d $dir;

    opendir(DIR, $dir) or die "can't opendir $dir: $!";
    my @scripts = grep { -f $_ } map { catfile($dir, $_) } sort readdir(DIR);
    closedir DIR;

    foreach my $script (@scripts) {
	print "Running 'perl $script'.\n";
	system("perl", "-I$CONFIG->{MODULE_DIR}", $script,
               '-u', $PG->{root_user}, '-p', $PG->{root_pass});
    }
}

print "\n\n==> Finished Database Upgrade <==\n\n";
