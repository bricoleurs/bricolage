#!/usr/bin/perl -w

=head1 Name

db.pl - installation script to launch the apropriate database instalation script

=head1 Description

This script is called during C<make install> to install the Bricolage
database.

=head1 Author

Sam Tregar <stregar@about-inc.com>

=head1 See Also

L<Bric::Admin>

=cut

use strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use Bric::Inst qw(:all);
use File::Spec::Functions qw(:ALL);
use File::Find qw(find);

our ($DB, $DBCONF);

print "\n\n==> Creating Bricolage Database <==\n\n";

$DBCONF = './database.db';
do $DBCONF or die "Failed to read $DBCONF : $!";

my $instdb;
$instdb = "./inst/dbload_$DB->{db_type}.pl";
do $instdb or die "Failed to launch $DB->{db_type} database loading script ($instdb)";

exit 0;
