#!/usr/bin/perl -w

=head1 NAME

clone_db.pl - installation script to clone an existing database

=head1 VERSION

$Revision: 1.5 $

=head1 DATE

$Date: 2004-03-19 05:52:51 $

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

our $PG;
do "./postgres.db" or die "Failed to read postgres.db: $!";

$ENV{PGHOST} = $PG->{host_name} if $PG->{host_name};
$ENV{PGPORT} = $PG->{host_port} if $PG->{host_port};

# dump out database
system(catfile($PG->{bin_dir}, 'pg_dump') .
       " -U$PG->{root_user} -O -x $PG->{db_name} > inst/Pg.sql");

exit 0;
