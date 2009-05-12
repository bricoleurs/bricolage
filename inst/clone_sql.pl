#!/usr/bin/perl -w

=head1 Name

clone_sql.pl - installation script to clone an existing database by launching apropriate database clone script

=head1 Description

This script is called during "make clone" to clone the Bricolage
database.

=head1 Author

Sam Tregar <stregar@about-inc.com>

=head1 See Also

L<Bric::Admin>

=cut

use FindBin;
use strict;

my $DB = do './database.db' or die "Failed to read database.db: $!";
my $script = "$FindBin::Bin/clone_sql_$DB->{db_type}.pl";
system ( $^X, $script ) and exit 1;
