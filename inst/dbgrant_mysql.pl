#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use Bric::Inst qw(:all);
use File::Spec::Functions qw(:ALL);

our ($DB, $DBCONF, $DBDEFDB, $ERR_FILE);
$DBCONF = './database.db';
do $DBCONF or die "Failed to read $DBCONF : $!";

# Set variables for mysql
$DB->{exec} .= "-h $DB->{host_name} "
    if $DB->{host_name} && $DB->{host_name} ne 'localhost';
$DB->{exec} .= "-P $DB->{host_port} " if $DB->{host_port} ne '';
$ERR_FILE = catfile tmpdir, '.db.stderr';
#END { unlink $ERR_FILE }


print "\n\n==> Granting access rights to Bricolage Mysql user <==\n\n";

grant_permissions();

print "\n\n==> Finished granting access rights to Bricolage Mysql user <==\n\n";

exit 0;

sub grant_permissions {
    my $host = $DB->{host_name} ? '' : '@localhost';
    # assign all permissions to SYS_USER
    my $sql = qq{
        GRANT SELECT, UPDATE, INSERT, DELETE
        ON    "$DB->{db_name}".*
        TO    "$DB->{sys_user}"$host
    };
    $sql .= "    IDENTIFIED BY '$DB->{sys_pass}'\n" if $DB->{sys_pass};

    my $err = exec_sql($sql);
    hard_fail("Failed to Grant privileges. The database error was\n\n$err")
      if $err;

    $err = exec_sql('FLUSH PRIVILEGES');
    hard_fail("Failed to flush privileges. The database error was\n\n$err")
      if $err;

    print "Done.\n";
}

sub exec_sql {
    my ($sql, $file, $db, $res, $user, $pass) = @_;
    $db ||= $DB->{db_name} if $db;
    my $exec = "$DB->{exec}";
    if (my $u = $user || $DB->{root_user}) {
        $exec .= " -u $u";
    }
    if (my $pwd = $pass || $DB->{root_pass}) {
        $exec .= " -p$pwd";
    }

    # System returns 0 on success, so just return if it succeeds.
    open STDERR, ">$ERR_FILE" or die "Cannot redirect STDERR to $ERR_FILE: $!\n";

    if ($res) {
        $exec .= qq{ -e "$sql" } if $sql;
        $exec .= " -D $db" if $db;
        $exec .= " -P format=unaligned -P pager= -P footer=";
        $exec .= " < $file " if !$sql;
#        print $exec."\n";
        @$res = `$exec`;
        # Shift off the column headers.
        shift @$res;
        return unless $?;
    } else {
        $exec .= qq{ -e "$sql" } if $sql;
        $exec .= " -D $db " if $db;
        $exec .= " < $file " if !$sql;
#        print $exec."\n";
        system($exec) or return;
    }

    # We encountered a problem.
    open ERR, "<$ERR_FILE" or die "Cannot open $ERR_FILE: $!\n";
    local $/;
    return <ERR>;
}
