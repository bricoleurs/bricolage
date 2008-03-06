#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use Bric::Inst qw(:all);
use File::Spec::Functions qw(:ALL);

our ($PG, $PGCONF, $PGDEFDB, $ERR_FILE);
$PGCONF = './postgres.db';
do $PGCONF or die "Failed to read $PGCONF : $!";

# Switch to postgres system user
if (my $sys_user = $PG->{system_user}) {
    print "Becoming $sys_user...\n";
    $> = $PG->{system_user_uid};
    $< = $PG->{system_user_uid};
    die "Failed to switch EUID and RUID to $PG->{system_user_uid} ($sys_user).\n"
        unless $> == $PG->{system_user_uid} and $< == $PG->{system_user_uid};
}

# Set environment variables for psql.
$ENV{PGUSER} = $PG->{root_user};
$ENV{PGPASSWORD} = $PG->{root_pass};
$ENV{PGHOST} = $PG->{host_name} if $PG->{host_name};
$ENV{PGPORT} = $PG->{host_port} if $PG->{host_port};
$ERR_FILE = catfile tmpdir, '.db.stderr';
END { unlink $ERR_FILE }

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
        my $sql = $PG->{version} ge '7.3'
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
            TO    "$PG->{sys_user}";
        };
        $err = exec_sql($sql);
        hard_fail("Failed to Grant privileges. The database error was\n\n$err")
            if $err;
    }

    print "Done.\n";
}

sub exec_sql {
    my ($sql, $file, $db, $res) = @_;
    $db ||= $PG->{db_name};
    # System returns 0 on success, so just return if it succeeds.
    open STDERR, ">$ERR_FILE" or die "Cannot redirect STDERR to $ERR_FILE: $!\n";
    if ($res) {
        my @args = $sql ? ('-c', qq{"$sql"}) : ('-f', $file);
        @$res = `$PG->{psql} --variable ON_ERROR_STOP=1 -q @args -d $db -P format=unaligned -P pager= -P footer=`;
        # Shift off the column headers.
        shift @$res;
        return unless $?;
    } else {
        my @args = $sql ? ('-c', $sql) : ('-f', $file);
        system($PG->{psql}, '--variable', 'ON_ERROR_STOP=1', '-q', @args, '-d', $db)
          or return;
    }

    # We encountered a problem.
    open ERR, "<$ERR_FILE" or die "Cannot open $ERR_FILE: $!\n";
    local $/;
    return <ERR>;
}

