#!/usr/bin/perl -w

=head1 NAME

db.pl - installation script to install database

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$LastChangedDate$

=head1 DESCRIPTION

This script is called during C<make install> to install the Bricolage
database.

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
use File::Find qw(find);

our ($PG, $PGCONF, $PGDEFDB, $ERR_FILE);

print "\n\n==> Creating Bricolage Database <==\n\n";

$PGCONF = './postgres.db';
do $PGCONF or die "Failed to read $PGCONF : $!";

# Switch to postgres system user
if (my $sys_user = $PG->{system_user}) {
    print "Becoming $sys_user...\n";
    $> = $PG->{system_user_uid};
    die "Failed to switch EUID to $PG->{system_user_uid} ($sys_user).\n"
        unless $> == $PG->{system_user_uid};
}

# Set environment variables for psql.
$ENV{PGUSER} = $PG->{root_user};
$ENV{PGPASSWORD} = $PG->{root_pass};
$ENV{PGHOST} = $PG->{host_name} if ( $PG->{host_name} ne "localhost" );
$ENV{PGPORT} = $PG->{host_port} if ( $PG->{host_port} ne "" );
$ERR_FILE = catfile tmpdir, '.db.stderr';
END { unlink $ERR_FILE if $ERR_FILE && -e $ERR_FILE }

$PGDEFDB = 'template1';
create_db();
create_user();

# load data.
load_db();

print "\n\n==> Finished Creating Bricolage Database <==\n\n";
exit 0;

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

# create the database, optionally dropping an existing database
sub create_db {
    print "Creating database named $PG->{db_name}...\n";
    my $err = exec_sql(qq{CREATE DATABASE "$PG->{db_name}" WITH ENCODING = 'UNICODE'}
                       . " TEMPLATE = template0",
                       0, $PGDEFDB);

    if ($err) {
        # There was an error. Offer to drop the database if it already exists.
        if ($err =~ /database "[^"]+" already exists/) {
            if (ask_yesno("Database named \"$PG->{db_name}\" already exists.  ".
                          "Drop database?", 0)) {
                # Drop the database.
                if ($err = exec_sql(qq{DROP DATABASE "$PG->{db_name}"}, 0,
                                    $PGDEFDB)) {
                    hard_fail("Failed to drop database.  The database error ",
                              "was:\n\n$err\n")
                }
                return create_db();
            } else {
                unless (ask_yesno("Create tables in existing database?", 1)) {
                    unlink $PGCONF;
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
    my $user = $PG->{sys_user};
    my $pass = $PG->{sys_pass};

    print "Creating user named $PG->{sys_user}...\n";
    my $err = exec_sql(qq{CREATE USER "$user" WITH password '$pass' } .
                       "NOCREATEDB NOCREATEUSER", 0, $PGDEFDB);

    if ($err) {
        if ($err =~ /(?:user|role)(?: name)? "[^"]+" already exists/) {
            if (ask_yesno("User named \"$PG->{sys_user}\" already exists. "
                          . "Continue with this user?", 1)) {
                # Just use the existing user.
                return;
            } elsif (ask_yesno("Well, shall we drop and recreate user? "
                               . "Doing so may affect other database "
                               . "permissions, so it's not recommended.", 0)) {
                if ($err = exec_sql(qq{DROP USER "$PG->{sys_user}"}, 0, $PGDEFDB)) {
                    hard_fail("Failed to drop user. The database error was:\n\n",
                              "$err\n");
                }
                return create_user();
            } elsif (ask_yesno("Okay, so do you want to continue with "
                               . "user \"$PG->{sys_user}\" after all?", 1)) {
                # Just use the existing user.
                return;
            } else {
                hard_fail("Cannot proceed with database user "
                          . "\"$PG->{sys_user}\"\n");
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
    my $db_file = $ENV{PGSQL} || catfile('inst', 'Pg.sql');
    unless (-e $db_file and -s _) {
        my $errmsg = "Missing or empty $db_file!\n\n"
          . "If you're using Subversion, you need to `make dist` first.\n"
          . "See `perldoc Bric::FAQ` for more information.";
        hard_fail($errmsg);
    }

    print "Loading Bricolage Database (this may take a few minutes).\n";
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
