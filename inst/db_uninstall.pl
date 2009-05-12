#!/usr/bin/perl -w

=head1 Name

db_uninstall.pl - installation script to launch apropriate database uninstall script

=head1 Description

This script is called during C<make uninstall> to launch the apropriate
uninstall Bricolage database script.

=head1 Author

Sam Tregar <stregar@about-inc.com>

Scott Lanning <slanning@theworld.com>

=head1 See Also

L<Bric::Admin>

=cut

use strict;
use File::Spec::Functions qw(:ALL);

my $DB = do './database.db' or die "Failed to read database.db : $!";

my $uninstdb = "./inst/db_uninst_$DB->{db_type}.pl";
do $uninstdb or die "Failed to launch $DB->{db_type} database loading script ($uninstdb)";
