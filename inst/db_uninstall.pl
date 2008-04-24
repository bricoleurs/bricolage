#!/usr/bin/perl -w

=head1 NAME

db_uninstall.pl - installation script to launch apropriate database uninstall script

=head1 VERSION

$LastChangedRevision$

=head1 DESCRIPTION

This script is called during C<make uninstall> to launch the apropriate 
uninstall Bricolage database script.

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


print "\n\n==> Deleting Bricolage Database <==\n\n";

our $DB;
do "./database.db" or die "Failed to read database.db : $!";

my $uninstdb;
$uninstdb = "./inst/db_uninst_$DB->{db_type}.pl";
do $uninstdb or die "Failed to launch $DB->{db_type} database loading script ($uninstdb)";    

exit 0;


