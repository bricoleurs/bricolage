#!/usr/bin/perl -w

=head1 NAME

db_upgrade.pl - installation script to run db upgrade scripts

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$LastChangedDate$

=head1 DESCRIPTION

This script is called by "make upgrade" to run the database upgrade
scripts.  Uses upgrade.db to determine which ones to run.

When multiple scripts are run, they are run in sorted ASCII-betical
order (via perl's C<sort()> function).

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
use File::Path;

our $UPGRADE;
do "./upgrade.db" or die "Failed to read upgrade.db : $!";
our $CONFIG;
do "./config.db" or die "Failed to read config.db : $!";
our $PG;
do './postgres.db' or die "Failed to read postgres.db : $!";

# Create a directory that the PG user can, uh, use.
my $tmpdir = catdir 'inst', 'db_tmp';
eval { mkpath $tmpdir };
if (my $err = $@) {
    die "Cannot create '$tmpdir': $err\n";
}
chown $PG->{system_user_uid}, -1, $tmpdir
  or die "Cannot chown '$tmpdir' to $PG->{ROOT_USER}: $!\n";

# Set environment variables for psql.
$ENV{PGUSER} = $PG->{root_user};
$ENV{PGPASSWORD} = $PG->{root_pass};
$ENV{PGHOST} = $PG->{host_name} if ( $PG->{host_name} ne "localhost" );
$ENV{PGPORT} = $PG->{host_port} if ( $PG->{host_port} ne "" );

print "\n\n==> Starting Database Upgrade <==\n\n";

# setup environment to ensure scripts run correctly
$ENV{BRICOLAGE_ROOT} = $UPGRADE->{BRICOLAGE_ROOT};
my $perl = $ENV{PERL} || $^X;
$ENV{PERL5LIB} = $CONFIG->{MODULE_DIR};

# run the upgrade scripts
foreach my $v (@{$UPGRADE->{TODO}}) {
    my $dir = catdir("inst", "upgrade", $v);
    print "Looking for scripts for $v in $dir\n";
    next unless -d $dir;

    opendir(DIR, $dir) or die "can't opendir $dir: $!";
    my @scripts = grep { -f $_ and $_ =~ /\.pl$/ }
        map { catfile($dir, $_) } sort readdir(DIR);
    closedir DIR;

    foreach my $script (@scripts) {
        print "Running '$perl $script'.\n";
        my $ret = system(
            "$perl", $script,
            '-u', $PG->{root_user},
            '-p', $PG->{root_pass},
            '-i', $PG->{system_user_uid},
            '-s', $PG->{system_user},
        );

        # Pass through abnormal exits so that `make` will be halted.
        exit $ret / 256 if $ret;
    }
}

print "\n\n==> Finished Database Upgrade <==\n\n";
