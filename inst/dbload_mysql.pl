#!/usr/bin/perl -w

=head1 Name

dbload_mysql.pl - installation script to install MySQL database

=head1 Description

This script is called during C<make install> to install the Bricolage
database.

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
use File::Find qw(find);

our ($DB, $DBCONF, $DBDEFDB, $ERR_FILE);

$DBCONF = './database.db';
do $DBCONF or die "Failed to read $DBCONF : $!";

my $verb = $DB->{create_db} ? 'Creating' : 'Initializing';
print "\n\n==> $verb Bricolage MySQL Database <==\n\n";

$ERR_FILE = catfile tmpdir, '.initdb.stderr';
END { unlink $ERR_FILE if $ERR_FILE && -e $ERR_FILE }

if ($DB->{create_db}) {
    # Set variables for mysql
    $DB->{exec} .= " -u $DB->{root_user} ";
    $DB->{exec} .= "-p$DB->{root_pass} " if $DB->{root_pass};
    $DB->{exec} .= "-h $DB->{host_name} "
    if $DB->{host_name} && $DB->{host_name} ne 'localhost';
        $DB->{exec} .= "-P $DB->{host_port} " if $DB->{host_port} ne '';

    $ERR_FILE = catfile tmpdir, '.db.stderr';
    END { unlink $ERR_FILE if $ERR_FILE && -e $ERR_FILE }

    create_db();
    create_user();
} else {
    # Set variables for mysql user
    $DB->{exec} .= " -u $DB->{sys_user} ";
    $DB->{exec} .= "-p$DB->{sys_pass} " if $DB->{sys_pass};
}

# Set variables for host name and port.
$DB->{exec} .= "-h $DB->{host_name} "
if $DB->{host_name} && $DB->{host_name} ne 'localhost';
    $DB->{exec} .= "-P $DB->{host_port} " if $DB->{host_port} ne '';

# load data.
load_db();

print "\n\n==> Finished $verb Bricolage MySQL Database <==\n\n";
exit 0;

sub exec_sql {
    my ($sql, $file, $db, $res) = @_;
    $db ||= $DB->{db_name} if $db;
    # System returns 0 on success, so just return if it succeeds.
    open STDERR, ">$ERR_FILE" or die "Cannot redirect STDERR to $ERR_FILE: $!\n";

    if ($res) {
        my $exec="$DB->{exec} ";
        $exec .="-e \"$sql\" " if $sql;
        $exec .="-D $db " if $db;
        $exec .="-P format=unaligned -P pager= -P footer= ";
        $exec .=" < $file " if !$sql;
        @$res = `$exec`;
        # Shift off the column headers.
        shift @$res;
        return unless $?;
    } else {
        my $exec="$DB->{exec} ";
        $exec .="-e \"$sql\" " if $sql;
        $exec .="-D $db " if $db;
        $exec .=" < $file " if !$sql;
        system($exec) or return;
    }

    # We encountered a problem.
    close STDERR;
    open ERR, "<$ERR_FILE" or die "Cannot open $ERR_FILE: $!\n";
    local $/;
    return <ERR>;
}

# create the database, optionally dropping an existing database
sub create_db {
    print "Creating database named $DB->{db_name}...\n";
    my $err = exec_sql(qq{CREATE DATABASE "$DB->{db_name}" DEFAULT CHARACTER
              SET utf8 DEFAULT COLLATE utf8_unicode_ci},0,0);

    if ($err) {
        # There was an error. Offer to drop the database if it already exists.
        if ($err =~ /database exists/) {
            if (ask_yesno("Database named \"$DB->{db_name}\" already exists.  ".
                          "Drop database?", $ENV{DEVELOPER}, $ENV{DEVELOPER})) {
                # Drop the database.
                if ($err = exec_sql(qq{DROP DATABASE "$DB->{db_name}"}, 0)) {
                    hard_fail("Failed to drop database.  The database error ",
                              "was:\n\n$err\n")
                }
                return create_db();
            } else {
                unless (ask_yesno("Create tables in existing database?", 1)) {
                    unlink $DBCONF;
                    hard_fail("Cannot proceed. If you want to use the existing ",
                              "database, run 'make upgrade'\ninstead. To pick a ",
                              "new database name, please run 'make db' again.\n");
                }
            }
            return 1;
        } else {
            hard_fail("Failed to create database. The database error was\n\n",
                      "$err\n");
        }
    }
    print "Database created.\n";
}

# create SYS_USER, optionally dropping an existing syst
sub create_user {
    my $user = $DB->{sys_user};
    my $pass = $DB->{sys_pass};

    print "Creating user named $DB->{sys_user}...\n";
    my $err = exec_sql(qq{CREATE USER "$user" IDENTIFIED BY '$pass' }
                       , 0);

    if ($err) {
        if ($err =~ /failed/) {
            if (ask_yesno("User named \"$DB->{sys_user}\" already exists. "
                          . "Continue with this user?", 1, $ENV{DEVELOPER})) {
                # Just use the existing user.
                return;
            } elsif (ask_yesno("Well, shall we drop and recreate user? "
                               . "Doing so may affect other database "
                               . "permissions, so it's not recommended.", 0)) {
                if ($err = exec_sql(qq{DROP USER "$DB->{sys_user}"}, 0, 0)) {
                    hard_fail("Failed to drop user. The database error was:\n\n",
                              "$err\n");
                }
                return create_user();
            } elsif (ask_yesno("Okay, so do you want to continue with "
                               . "user \"$DB->{sys_user}\" after all?", 1)) {
                # Just use the existing user.
                return;
            } else {
                hard_fail("Cannot proceed with database user "
                          . "\"$DB->{sys_user}\"\n");
            }
        } else {
            hard_fail("Failed to create database user.  The database error was:",
              "\n\n$err\n");
        }
    }
    print "User created.\n";
}

# load schema and data into database
sub load_db {
    my $db_file = $DB->{DBSQL} || catfile('inst', "$DB->{db_type}.sql");
    unless (-e $db_file and -s _) {
        my $errmsg = "Missing or empty $db_file!\n\n"
          . "If you're using Subversion, you need to `make dist` first.\n"
          . "See `perldoc Bric::FAQ` for more information.";
        hard_fail($errmsg);
    }

    print "Loading Bricolage MySQL Database (this may take a few minutes).\n";
    my $err = exec_sql(0, $db_file, $DB->{db_name});
    hard_fail("Error loading database. The database error was\n\n$err\n")
      if $err;
    print "\nDone.\n";
}
