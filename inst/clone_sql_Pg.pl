#!/usr/bin/perl -w

=head1 NAME

clone_sql_Pg.pl - installation script to clone an existing PG database 

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$LastChangedDate: 2006-06-20 01:00:31 +0300 (Tue, 20 Jun 2006) $

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

our $DB;
do "./database.db" or die "Failed to read database.db: $!";

# Switch to database system user
if (my $sys_user = $DB->{system_user}) {
    print "Becoming $sys_user...\n";
    $> = $DB->{system_user_uid};
    die "Failed to switch EUID to $DB->{system_user_uid} ($sys_user).\n"
        unless $> == $DB->{system_user_uid};
}

$ENV{PGHOST} = $DB->{host_name} if $DB->{host_name};
$ENV{PGPORT} = $DB->{host_port} if $DB->{host_port};

# dump out postgres database
system(catfile($DB->{bin_dir}, 'pg_dump') .
       " -U$DB->{root_user} -O -x $DB->{db_name} > inst/Pg.sql");

printf "\n\n==> Finished cloning Bricolage Database <==\n\n";

exit 0;
