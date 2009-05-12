#!/usr/bin/perl -w

=head1 Name

db_uninst_Pg.pl - installation script to uninstall PostgeSQL database

=head1 Description

This script is called during C<make uninstall> to uninstall the
PostgreSQL Bricolage database.

=head1 Author

Sam Tregar <stregar@about-inc.com>

Scott Lanning <slanning@theworld.com>

=head1 See Also

L<Bric::Admin>

=cut

use strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use Bric::Inst qw(:all);
use File::Spec::Functions qw(:ALL);
use File::Find qw(find);
use DBI;

print "\n\n==> Deleting Bricolage PostgreSQL Database <==\n\n";

our $DB;
do "./database.db" or die "Failed to read database.db : $!";
my $perl = $ENV{PERL} || $^X;

# Tell STDERR to ignore PostgreSQL NOTICE messages by forking another Perl to
# filter them out. This *must* happen before setting $> below, or Perl will
# complain.
open STDERR, "| $perl -ne 'print unless /^NOTICE:  /'"
  or die "Cannot pipe STDERR: $!\n";

# Switch to postgres system user
if (my $sys_user = $DB->{system_user}) {
    print "Becoming $sys_user...\n";
    require Config;
    $> = $DB->{system_user_uid};
    $< = $DB->{system_user_uid} if $Config::Config{d_setruid};
    die "Failed to switch EUID to $DB->{system_user_uid} ($sys_user).\n"
        unless $> == $DB->{system_user_uid};
}

# set environment variables for dbi:Pg
$ENV{PGHOST} = $DB->{host_name} if ( $DB->{host_name} ne "localhost" );
$ENV{PGPORT} = $DB->{host_port} if ( $DB->{host_port} ne "" );

# set environment variables for dbi:Pg
$ENV{PGHOST} = $DB->{host_name};
$ENV{PGPORT} = $DB->{host_port};

# setup database and user while connected to dummy template1
my $dbh = db_connect('template1');
drop_db($dbh);
drop_user($dbh);
$dbh->disconnect();

print "\n\n==> Finished Deleting Bricolage PostgreSQL Database <==\n\n";

# connect to a database
sub db_connect {
    my $name = shift;
    my $dbh = DBI->connect("dbi:Pg:dbname=$name",
                           $DB->{root_user}, $DB->{root_pass});
    hard_fail("Unable to connect to Postgres using supplied root username ",
              "and password: ", DBI->errstr, "\n")
        unless $dbh;
    $dbh->{PrintError} = 0;
    return $dbh;
}

# create the database, optionally dropping an existing database
sub drop_db {
    my $dbh = shift;

    if (ask_yesno("Drop database \"$DB->{db_name}\"?", 0)) {
        unless ($dbh->do("DROP DATABASE $DB->{db_name}")) {
            hard_fail("Failed to drop database.  The error from Postgres was:\n\n",
                      $dbh->errstr, "\n");
        }
        print "Database dropped.\n";
    }
}

# create SYS_USER, optionally dropping an existing syst
sub drop_user {
    my $dbh = shift;

    if (ask_yesno("Drop user \"$DB->{sys_user}\"?", 0)) {
        unless ($dbh->do("DROP USER $DB->{sys_user}")) {
            hard_fail("Failed to drop user.  The error from Postgres was:\n\n",
                      $dbh->errstr, "\n");
        }
        print "User dropped.\n";
    }
}
