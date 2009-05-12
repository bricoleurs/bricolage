#!/usr/bin/perl -w

=head1 Name

dbload_Pg.pl - installation script to install postgresql database

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
use File::Spec::Functions qw(:ALL);
use File::Find qw(find);

our ($DB, $DBCONF, $DBDEFDB, $ERR_FILE);

$DBCONF = './database.db';
do $DBCONF or die "Failed to read $DBCONF : $!";

my $verb = $DB->{create_db} ? 'Creating' : 'Initializing';
print "\n\n==> $verb Bricolage PostgreSQL Database <==\n\n";

$ERR_FILE = catfile tmpdir, '.db.stderr';
END { unlink $ERR_FILE if $ERR_FILE && -e $ERR_FILE }

# Set environment variables for psql.
$ENV{PGHOST} = $DB->{host_name} if $DB->{host_name} ne 'localhost';
$ENV{PGPORT} = $DB->{host_port} if $DB->{host_port} ne '';

if ($DB->{create_db}) {
    # Switch to database system user
    if (my $sys_user = $DB->{system_user}) {
        print "Becoming $sys_user...\n";
        require Config;
        $> = $DB->{system_user_uid};
        $< = $DB->{system_user_uid} if $Config::Config{d_setruid};
        die "Failed to switch EUID to $DB->{system_user_uid} ($sys_user).\n"
            unless $> == $DB->{system_user_uid};
    }

    # Set environment variables for psql.
    $ENV{PGUSER} = $DB->{root_user};
    $ENV{PGPASSWORD} = $DB->{root_pass};

    $DBDEFDB = 'template1';
    create_db();
    create_user();
} else {
    # Set environment variables for psql.
    $ENV{PGUSER} = $DB->{sys_user};
    $ENV{PGPASSWORD} = $DB->{sys_pass};
}

# load data.
load_db();

print "\n\n==> Finished $verb PostgreSQL Bricolage Database <==\n\n";
exit 0;

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

# create the database, optionally dropping an existing database
sub create_db {
    print "Creating database named $DB->{db_name}...\n";
    my $err = exec_sql(qq{CREATE DATABASE "$DB->{db_name}" WITH ENCODING = 'UNICODE'}
                       . " TEMPLATE = template0",
                       0, $DBDEFDB);

    if ($err) {
        # There was an error. Offer to drop the database if it already exists.
        if ($err =~ /database "[^"]+" already exists/) {
            if (ask_yesno("Database named \"$DB->{db_name}\" already exists.  ".
                          "Drop database?", $ENV{DEVELOPER}, $ENV{DEVELOPER})) {
                # Drop the database.
                if ($err = exec_sql(qq{DROP DATABASE "$DB->{db_name}"}, 0,
                                    $DBDEFDB)) {
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
    my $err = exec_sql(qq{CREATE USER "$user" WITH password '$pass' } .
                       "NOCREATEDB NOCREATEUSER", 0, $DBDEFDB);

    if ($err) {
        if ($err =~ /(?:user|role)(?: name)? "[^"]+" already exists/) {
            if (ask_yesno("User named \"$DB->{sys_user}\" already exists. "
                          . "Continue with this user?", 1, $ENV{DEVELOPER})) {
                # Just use the existing user.
                return;
            } elsif (ask_yesno("Well, shall we drop and recreate user? "
                               . "Doing so may affect other database "
                               . "permissions, so it's not recommended.", 0)) {
                if ($err = exec_sql(qq{DROP USER "$DB->{sys_user}"}, 0, $DBDEFDB)) {
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
    my $db_file = $ENV{DBSQL} || catfile('inst', 'Pg.sql');
    unless (-e $db_file and -s _) {
        my $errmsg = "Missing or empty $db_file!\n\n"
          . "If you're using Subversion, you need to `make dist` first.\n"
          . "See `perldoc Bric::FAQ` for more information.";
        hard_fail($errmsg);
    }

    print "Loading Bricolage Pg Database (this may take a few minutes).\n";
    my $err = exec_sql(0, $db_file);
    hard_fail("Error loading database. The database error was\n\n$err\n")
      if $err;
    print "\nDone.\n";

    # vacuum to create usable indexes
    print "Finishing database...\n";
    foreach my $maint ('vacuum', 'vacuum analyze') {
        my $err = exec_sql($maint);
        hard_fail("Error encountered during '$maint'. The database error ",
                  "was\n\n$err") if $err;
    }
    print "Done.\n";

    # all done!
    exit 0;
}
