#!/usr/bin/perl -w

=head1 NAME

clone_db.pl - installation script to clone an existing database

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$LastChangedDate$

=head1 DESCRIPTION

This script is called during "make clone" to clone the Bricolage
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

print "\n\n==> Cloning Bricolage Database <==\n\n";

our $DB;
do "./database.db" or die "Failed to read database.db: $!";

# Switch to database system user
if (my $sys_user = $DB->{system_user}) {
    print "Becoming $sys_user...\n";
    $> = $DB->{system_user_uid};
    die "Failed to switch EUID to $DB->{system_user_uid} ($sys_user).\n"
        unless $> == $DB->{system_user_uid};
}
if ($DB->{db} eq "pg") {
$ENV{PGHOST} = $DB->{host_name} if $DB->{host_name};
$ENV{PGPORT} = $DB->{host_port} if $DB->{host_port};

# dump out postgres database
system(catfile($DB->{bin_dir}, 'pg_dump') .
       " -U$DB->{root_user} -O -x $DB->{db_name} > inst/Pg.sql");
}
else 
{
$ENV{MYSQLHOST} = $DB->{host_name} if $DB->{host_name};
$ENV{MYSQLPORT} = $DB->{host_port} if $DB->{host_port};
# dump out mysql database
system(catfile($DB->{bin_dir}, 'mysqldump') .
       " -h $ENV{MYSQLHOST} -P $ENV{MYSQLPORT} -u$DB->{root_user} $DB->{db_name} > inst/My.sql");
}
exit 0;
