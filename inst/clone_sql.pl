#!/usr/bin/perl -w

=head1 NAME

clone_sql.pl - installation script to clone an existing database by launching apropriate
database clone script

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

do "./clone_sql_$DB->{db}.pl" or die "Failed to launch $DB->{db} clone script (./clone_sql_$DB->{db}.pl): $!";

exit 0;
