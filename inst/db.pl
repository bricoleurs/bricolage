#!/usr/bin/perl -w

=head1 NAME

db.pl - installation script to install database

=head1 VERSION

$Revision: 1.14 $

=head1 DATE

$Date: 2003-02-25 16:17:47 $

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

print "\n\n==> Creating Bricolage Database <==\n\n";

our $PG;
do "./postgres.db" or die "Failed to read postgres.db : $!";

# Set environment variables for psql.
$ENV{PGUSER} = $PG->{root_user};
$ENV{PGPASSWORD} = $PG->{root_pass};
our $ERR_FILE = '.db.stderr';
END { unlink $ERR_FILE }

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
        @$res = `$PG->{psql} -q @args -d $db -P format=unaligned -P pager= -P footer=`;
        return unless $?;
    } else {
        my @args = $sql ? ('-c', $sql) : ('-f', $file);
        system($PG->{psql}, '-q', @args, '-d', $db) or return;
    }

    # We encountered a problem.
    open ERR, "<.db.stderr" or die "Cannot open .db.stderr: $!\n";
    local $/;
    return <ERR>;
}

# create the database, optionally dropping an existing database
sub create_db {
    print "Creating database named $PG->{db_name}...\n";
    my $err = exec_sql("CREATE DATABASE $PG->{db_name} WITH ENCODING = 'UNICODE'",
                       0, 'template1');

    if ($err) {
        # There was an error. Offer to drop the datbase if it already exists.
        if ($err =~ /database "[^"]+" already exists/ and
            ask_yesno("Database named \"$PG->{db_name}\" already exists.  ".
                      "Drop database? [no] ", 0)) {
            if ($err = exec_sql("DROP DATABASE $PG->{db_name}", 0, 'template1')) {
                hard_fail("Failed to drop database.  The database error ",
                          "was:\n\n$err\n")
            }
            return create_db();
        } else {
            hard_fail("Failed to create database. The database error wase\n\n",
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
    my $err = exec_sql("CREATE USER $user WITH password '$pass' " .
                       "NOCREATEDB NOCREATEUSER", 0, 'template1');

    if ($err) {
        if ($err =~ /user name "[^"]+" already exists/) {
            if (ask_yesno("User named \"$PG->{sys_user}\" already exists.  ".
                          "Drop user? [no] ", 0)) {
                if ($err = exec_sql("DROP USER $PG->{sys_user}", 0,
                                    'template1')) {
                    hard_fail("Failed to drop user.  The database error was:\n\n",
                              "$err\n");
                }
                return create_user();
            } else {
                # We'll just use the existing user.
                return;
            }
        } else {
            hard_fail("Failed to create database user.  The databae error was:",
              "\n\n$err\n");
        }
    }
    print "User created.\n";
}

# load schema and data into database
sub load_db {
    # make sure we have a bricolage.sql and that it's not empty (this
    # can happen if you "make dist" from a distribution due to missing
    # .sql files)
    my $db_file = catfile('inst', 'Pg.sql');
    hard_fail("Missing or empty $db_file!")
      unless -e $db_file and -s _;

    print "Loading Bricolage Database. (this could take a few minutes)\n";
    exec_sql(0, $db_file);
    print "\nDone.\n";

    # assign all permissions to SYS_USER
    print "Granting privilages...\n";

    # get a list of all tables and sequences that don't start with pg
    my $sql = qq{
       SELECT relname
       FROM   pg_class
       WHERE  relkind IN ('r', 'S')
              AND relname NOT LIKE 'pg%';
    };

    my @objects;
    exec_sql($sql, 0, 0, \@objects);

    my $objects = join (', ', map { chomp; $_ } @objects);

    $sql = qq{
        GRANT SELECT, UPDATE, INSERT, DELETE
        ON    $objects
        TO    $PG->{sys_user}
    };
    exec_sql($sql);

    print "Done.\n";

    # vacuum to create usable indexes
    print "Finishing database...\n";
    exec_sql('vacuum');
    exec_sql('analyze');
    exec_sql('reindex');
    print "Done.\n";

    # all done!
    exit 0;
}
