#!/usr/bin/perl -w

=head1 NAME

clone_sql_mysql.pl - installation script to clone an existing mysql database 

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

print "\n\n==> Cloning Bricolage Database <==\n\n";

our $DB;
do "./database.db" or die "Failed to read database.db: $!";

# Make sure that we don't overwrite the existing Pg.sql.
chdir 'dist';

my $dbclone;
$dbclone = catfile($DB->{bin_dir}, 'mysqldump');
$dbclone = " -h $DB->{host_name} " if $DB->{host_name};
$dbclone = " -P $DB->{host_port} " if $DB->{host_port};

# dump out mysql database
system($dbclone ." -u $DB->{root_user} -p$DB->{root_pass} -D $DB->{db_name} > mysql.sql");
}
exit 0;
