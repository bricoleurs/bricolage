#!/usr/bin/perl -w

=head1 NAME

db.pl - installation script to uninstall database

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$LastChangedDate$

=head1 DESCRIPTION

This script is called during C<make uninstall> to install the Bricolage
database.

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

Scott Lanning <slanning@theworld.com>

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

print "\n\n==> Deleting Bricolage Database <==\n\n";

our $PG;
do "./postgres.db" or die "Failed to read postgres.db : $!";
my $perl = $ENV{PERL} || $^X;

# Tell STDERR to ignore PostgreSQL NOTICE messages by forking another Perl to
# filter them out. This *must* happen before setting $> below, or Perl will
# complain.
open STDERR, "| $perl -ne 'print unless /^NOTICE:  /'"
  or die "Cannot pipe STDERR: $!\n";

# Switch to postgres system user
if (my $sys_user = $PG->{system_user}) {
    print "Becoming $sys_user...\n";
    $> = $PG->{system_user_uid};
    die "Failed to switch EUID to $PG->{system_user_uid} ($sys_user).\n"
        unless $> == $PG->{system_user_uid};
}

# set environment variables for dbi:Pg
$ENV{PGHOST} = $PG->{host_name} if ( $PG->{host_name} ne "localhost" );
$ENV{PGPORT} = $PG->{host_port} if ( $PG->{host_port} ne "" );

# set environment variables for dbi:Pg
$ENV{PGHOST} = $PG->{host_name};
$ENV{PGPORT} = $PG->{host_port};

# setup database and user while connected to dummy template1
my $dbh = db_connect('template1');
drop_db($dbh);
drop_user($dbh);
$dbh->disconnect();

print "\n\n==> Finished Deleting Bricolage Database <==\n\n";
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
sub drop_db {
    my $dbh = shift;

    if (ask_yesno("Drop database \"$PG->{db_name}\"? [no] ", 0)) {
        unless ($dbh->do("DROP DATABASE $PG->{db_name}")) {
            hard_fail("Failed to drop database.  The error from Postgres was:\n\n",
                      $dbh->errstr, "\n");
        }
        print "Database dropped.\n";
    }
}

# create SYS_USER, optionally dropping an existing syst
sub drop_user {
    my $dbh = shift;

    if (ask_yesno("Drop user \"$PG->{sys_user}\"? [no] ", 0)) {
        unless ($dbh->do("DROP USER $PG->{sys_user}")) {
            hard_fail("Failed to drop user.  The error from Postgres was:\n\n",
                      $dbh->errstr, "\n");
        }
        print "User dropped.\n";
    }
}
