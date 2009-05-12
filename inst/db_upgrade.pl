#!/usr/bin/perl -w

=head1 Name

db_upgrade.pl - installation script to run db upgrade scripts

=head1 Description

This script is called by "make upgrade" to run the database upgrade
scripts.  Uses upgrade.db to determine which ones to run.

When multiple scripts are run, they are run in sorted ASCII-betical
order (via perl's C<sort()> function).

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
use File::Path;

our $UPGRADE;
do "./upgrade.db" or die "Failed to read upgrade.db : $!";
our $CONFIG;
do "./config.db" or die "Failed to read config.db : $!";
our $DB;
do './database.db' or die "Failed to read database.db : $!";

# Create a directory that the PG user can, uh, use.
my $tmpdir = catdir 'inst', 'db_tmp';
eval { mkpath $tmpdir };
if (my $err = $@) {
    die "Cannot create '$tmpdir': $err\n";
}

if ($DB->{system_user_uid}) {
    chown $DB->{system_user_uid}, -1, $tmpdir
        or die "Cannot chown '$tmpdir' to $DB->{ROOT_USER}: $!\n";
}

# Set environment variables for psql.
$ENV{PGUSER} = $DB->{root_user};
$ENV{PGPASSWORD} = $DB->{root_pass};
$ENV{PGHOST} = $DB->{host_name} if ( $DB->{host_name} ne "localhost" );
$ENV{PGPORT} = $DB->{host_port} if ( $DB->{host_port} ne "" );

print "\n\n==> Starting Database Upgrade <==\n\n";

# setup environment to ensure scripts run correctly
$ENV{BRICOLAGE_ROOT} = $UPGRADE->{BRICOLAGE_ROOT};
my $perl = $ENV{PERL} || $^X;
$ENV{PERL5LIB} = $CONFIG->{MODULE_DIR};

# setup database type in order to use apropriate upgrade scripts
# the database type has to be in the script name (Pg, mysql)
my ($x,$y,$z);

# run the upgrade scripts
foreach my $v (@{$UPGRADE->{TODO}}) {
    my $dir = catdir("inst", "upgrade", $v);
    ($x, $y, $z) = $v =~ /(\d+)\.(\d+)(?:\.(\d+))?/;
    print "Looking for scripts for $v in $dir\n";
    next unless -d $dir;

    opendir(DIR, $dir) or die "can't opendir $dir: $!";

# check for different database types starting with version 1.10.2
    my @scripts;
    if (($x > 1) or ($x == 1 and $y > 10) or ($x == 1 and $y== 10 and $z > 2)) {
        @scripts = grep { -f $_ and $_ =~ /\.pl$/ }
        map { catfile($dir, $_) } sort readdir(DIR);
    }
    else {
        @scripts = grep { -f $_ and $_ =~ /\.pl$/}
        map { catfile($dir, $_) } sort readdir(DIR);
    }
    closedir DIR;

    foreach my $script (@scripts) {
        print "Running '$perl $script'.\n";
        my $ret = system(
            $perl, $script,
            '-u', $DB->{root_user},
            '-p', $DB->{root_pass},
            '-i', $DB->{system_user_uid} || '',
            '-s', $DB->{system_user} || '',
        );

        # Pass through abnormal exits so that `make` will be halted.
        exit $ret / 256 if $ret;
    }
    system $perl, catfile($FindBin::Bin, 'dbgrant.pl'), @ARGV and die;
}

print "\n\n==> Finished Database Upgrade <==\n\n";
