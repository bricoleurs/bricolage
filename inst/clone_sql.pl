#!/usr/bin/perl -w

=head1 NAME

clone_db.pl - installation script to clone an existing database

=head1 VERSION

$Revision: 1.1 $

=head1 DATE

$Date: 2002-08-13 22:05:10 $

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
do "./postgres.db" or die "Failed to read postgres.db : $!";

# dump out database (NOTE: when the installer uses psql to load
# bricolage.sql drop the -d for a speedup)
system(catfile($PG->{bin_dir}, 'pg_dump') .
       " -U$PG->{root_user} -O -x -d $PG->{db_name} > inst/bricolage.sql.tmp");

# fix problem with the Usr table's circular dependecy on login_avail().
open(TMP, "inst/bricolage.sql.tmp") or die $!;
open(SQL, ">inst/bricolage.sql") or die $!;
while(<TMP>) {
    next if /CONSTRAINT "ck_usr__login"/;
    print SQL $_;
}
close TMP;
print SQL "\nALTER TABLE usr ADD CONSTRAINT ck_usr__login ",
  "CHECK (login_avail(LOWER(login), active, id));\n";
close SQL;
unlink "inst/bricolage.sql.tmp" or die $!;
    
print "\n\n==> Finished Cloning Bricolage Database <==\n\n";
exit 0;
