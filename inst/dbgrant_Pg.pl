#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use Bric::Inst qw(:all);
use File::Spec::Functions qw(:ALL);

our ($DB, $DBCONF, $DBDEFDB, $ERR_FILE);
$DBCONF = './database.db';
do $DBCONF or die "Failed to read $DBCONF : $!";

# Switch to postgres system user
if (my $sys_user = $DB->{system_user}) {
    print "Becoming $sys_user...\n";
    require Config;
    $> = $DB->{system_user_uid};
    $< = $DB->{system_user_uid} if $Config::Config{d_setruid};
    die "Failed to switch EUID to $DB->{system_user_uid} ($sys_user).\n"
        unless $> == $DB->{system_user_uid};
}

# Set environment variables for psql.
use Data::Dumper;
$ENV{PGUSER} = $DB->{root_user};
$ENV{PGPASSWORD} = $DB->{root_pass};
$ENV{PGHOST} = $DB->{host_name} if $DB->{host_name};
$ENV{PGPORT} = $DB->{host_port} if $DB->{host_port};
BEGIN { $ERR_FILE = catfile tmpdir, '.db.stderr' }
END { unlink $ERR_FILE if $ERR_FILE && -e $ERR_FILE }

grant_permissions();

sub grant_permissions {
    # assign all permissions to SYS_USER
    print "Granting privileges...\n";

    for my $spec (
        [ 'r', 'SELECT, UPDATE, INSERT, DELETE' ],
        [ 'S', 'SELECT, UPDATE'                 ],
    ) {
        my ($type, $grant) = @$spec;

        # get a list of all tables and sequences that don't start with pg
        my $sql = $DB->{version} ge '7.3'
            ? qq{
            SELECT n.nspname || '.' || c.relname
            FROM   pg_catalog.pg_class c
                   LEFT JOIN pg_catalog.pg_user u ON u.usesysid = c.relowner
                   LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
            WHERE  c.relkind = '$type'
                   AND n.nspname NOT IN ('pg_catalog', 'pg_toast')
                   AND pg_catalog.pg_table_is_visible(c.oid)
          }
          : qq{
            SELECT relname
            FROM   pg_class
            WHERE  relkind = '$type'
                   AND relname NOT LIKE 'pg%';
          };

        my @objects;
        my $err = exec_sql($sql, 0, 0, \@objects);
        hard_fail("Failed to get list of objects. The database error was\n\n",
                  "$err\n") if $err;

        my $objects = join (', ', map { chomp; $_ } @objects);

        $sql = qq{
            GRANT $grant
            ON    $objects
            TO    "$DB->{sys_user}";
        };
        $err = exec_sql($sql);
        hard_fail("Failed to Grant privileges. The database error was\n\n$err")
            if $err;
    }

    print "Done.\n";
}

sub exec_sql {
    my ($sql, $file, $db, $res) = @_;
    $db ||= $DB->{db_name};
    # System returns 0 on success, so just return if it succeeds.
    open STDERR, ">$ERR_FILE" or die "Cannot redirect STDERR to $ERR_FILE: $!\n";
    if ($res) {
        my @args = $sql ? ('-c', qq{"$sql"}) : ('-f', $file);
        @$res = `$DB->{exec} --variable ON_ERROR_STOP=1 -q @args -d $db -P format=unaligned -P pager= -P tuples_only=`;
        return unless $?;
    } else {
        my @args = $sql ? ('-c', $sql) : ('-f', $file);
        system($DB->{exec}, '--variable', 'ON_ERROR_STOP=1', '-q', @args, '-d', $db)
          or return;
    }

    # We encountered a problem.
    open ERR, "<$ERR_FILE" or die "Cannot open $ERR_FILE: $!\n";
    local $/;
    return <ERR>;
}

