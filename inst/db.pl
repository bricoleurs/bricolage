#!/usr/bin/perl -w

=head1 NAME

db.pl - installation script to install database

=head1 VERSION

$Revision: 1.7 $

=head1 DATE

$Date: 2002-08-30 23:31:30 $

=head1 DESCRIPTION

This script is called during "make install" to install the Bricolage
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
use DBI;

print "\n\n==> Creating Bricolage Database <==\n\n";

our $PG;
do "./postgres.db" or die "Failed to read postgres.db : $!";

# Tell STDERR to ignore PostgreSQL NOTICE messages by forking another Perl to
# filter them out. This *must* happen before setting $> below, or Perl will
# complain.
open STDERR, "| perl -ne 'print unless /^NOTICE:  /'"
  or die "Cannot pipe STDERR: $!\n";

# Switch to postgres system user
print "Becoming $PG->{system_user}...\n";
$> = $PG->{system_user_uid};
die "Failed to switch EUID to $PG->{system_user_uid} ($PG->{system_user}).\n"
    unless $> == $PG->{system_user_uid};

# setup database and user while connected to dummy template1
my $dbh = db_connect('template1');
create_db($dbh);
create_user($dbh);
$dbh->disconnect;

# load data - done in a forked process to avoid nasty NOTICEs that
# look like errors but aren't.
waitpid(load_db(), 0);

print "\n\n==> Finished Creating Bricolage Database <==\n\n";
exit 0;

# connect to a database
sub db_connect {
    my $name = shift;
    my $dbh = DBI->connect("dbi:Pg:dbname=$name",
                           $PG->{root_user}, $PG->{root_pass});
    hard_fail("Unable to connect to Postgres using supplied root username ",
              "and password: ", DBI->errstr, "\n")
        unless $dbh;
    $dbh->{PrintError} = 0;
    return $dbh;
}

# create the database, optionally dropping an existing database
sub create_db {
    my $dbh = shift;
    print "Creating database named $PG->{db_name}...\n";
    my $result = $dbh->do("CREATE DATABASE $PG->{db_name}");

    # if the database already exists offer to drop it
    if (not $result and
        $dbh->errstr =~ /database "[^"]+" already exists/ and
        ask_yesno("Database named \"$PG->{db_name}\" already exists.  ".
                  "Drop database? [no] ", 0)) {
        hard_fail("Failed to drop database.  The error from Postgres was:\n\n",
                  $dbh->errstr, "\n")
            unless $dbh->do("DROP DATABASE $PG->{db_name}");
        return create_db($dbh);
    }

    # else, hard fail if unable to create
    hard_fail("Failed to create database.  The error from Postgres was:\n\n",
              $dbh->errstr, "\n")
        unless $result;

    print "Database created.\n";
}

# create SYS_USER, optionally dropping an existing syst
sub create_user {
    my $dbh = shift;
    my $user = $PG->{sys_user};
    my $pass = $PG->{sys_pass};

    print "Creating user named $PG->{sys_user}...\n";
    my $result = $dbh->do("CREATE USER $user WITH password '$pass' ".
                          "NOCREATEDB NOCREATEUSER");

    # if the user already exists offer to drop it
    if (not $result and 
        $dbh->errstr =~ /user name "[^"]+" already exists/ and
        ask_yesno("User named \"$PG->{sys_user}\" already exists.  ".
                  "Drop user? [no] ", 0)) {
        hard_fail("Failed to drop user.  The error from Postgres was:\n\n",
                  $dbh->errstr, "\n")
            unless $dbh->do("DROP USER $PG->{sys_user}");
        return create_user($dbh);
    }

    hard_fail("Failed to create database user.  The error from Postgres was:",
              "\n\n", $dbh->errstr, "\n")
        unless $result;

    print "User created.\n";
}

# load schema and data into database
sub load_db {
    # make sure we have a bricolage.sql and that it's not empty (this
    # can happen if you "make dist" from a distribution due to missing
    # .sql files)
    hard_fail("Missing or empty inst/bricolage.sql!")
      unless -e "inst/bricolage.sql" and -s _;

    # open bricolage.sql, created in an earlier rule or by "make dist"
    # in days gone by.
    open(SQL, "inst/bricolage.sql")
        or die "Unable to open inst/bricolage.sql : $!";

    print "Loading Bricolage Database. (this could take a few minutes)\n";

    # connect to target database
    my $dbh = db_connect($PG->{db_name});

    # run through sql executing queries as they are found
    my $sql = "";
    my ($result, $in_comment);
    my $i;        # For status dot calculations.
    local $| = 1; # Don't buffer status dots.
    while (<SQL>) {
        next if /^--/ or /^\s*$/; # skip simple comments and blank lines

        # check for an end comment block
        if (m|\*/|) {
            $in_comment = 0;
            next;
        }

        # skip if we are in a commented block
        next if $in_comment;

        # check for a start comment block
        if (m|/\*|) {
            $in_comment = 1;
            next;
        }

        # if we are at the end of the statement, execute it
        if (s/;\s*$//) {
            hard_fail("Database error on statement:\n\n",
                      $sql, "\n\nError was:\n\n", $dbh->errstr, "\n")
              unless ($dbh->do($sql . $_));
            $sql = '';
            # Output a dot every twenty statements.
            print '.' unless ++$i % 20;
            next;
        }

        # otherwise, concat and keep looking
        $sql .= $_;
    }
    close(SQL);
    print "\nDone.\n";

    # assign all permissions to SYS_USER
    print "Granting privilages...\n";

    # get a list of all tables and sequences that don't start with pg
    my $objects = $dbh->selectcol_arrayref(<<'END');
SELECT relname
FROM pg_class
WHERE (relkind = 'S' OR relkind = 'r') AND
      relname NOT LIKE 'pg%'
END
    die $dbh->errstr unless $objects;

    # loop over objects assigning perms
    foreach my $obj (@$objects) {
        my $r = $dbh->do("GRANT SELECT, UPDATE, INSERT, DELETE ".
                         "ON $obj TO $PG->{sys_user}");
        hard_fail("Database error granting permissions on $obj:\n\n",
                  "Error was:\n\n", $dbh->errstr, "\n")
          unless $r;
    }

    print "Done.\n";

    # vacuum to create usable indexes
    print "Finishing database...\n";
    $dbh->do('VACUUM ANALYZE');
    print "Done.\n";

    # all done - disconnect and kill this processes
    $dbh->disconnect;
    exit 0;
}
