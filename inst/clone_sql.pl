#!/usr/bin/perl -w

=head1 NAME

clone_db.pl - installation script to clone an existing database

=head1 VERSION

$Revision: 1.1.6.1 $

=head1 DATE

$Date: 2003-04-29 21:19:51 $

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
# Pg.sql drop the -d for a speedup)
system(catfile($PG->{bin_dir}, 'pg_dump') .
       " -U$PG->{root_user} -O -x -d $PG->{db_name} > inst/Pg.sql.tmp");

# fix problem with the Usr table's circular dependecy on login_avail().
open(TMP, "inst/Pg.sql.tmp") or die $!;
open(SQL, ">inst/Pg.sql") or die $!;
my $last;
while(<TMP>) {
    if (/CONSTRAINT\s+"?ck_usr__login"?/) {
        $last =~ s/,\s*$//;
        print SQL $last if $last;
        $last = '';
    } else {
        print SQL $last if $last;
        $last = $_;
    }
}
print SQL $last if $last;
close TMP;
print SQL "\nALTER TABLE usr ADD CONSTRAINT ck_usr__login ",
  "CHECK (login_avail(LOWER(login), active, id));\n";
close SQL;
unlink "inst/Pg.sql.tmp" or die $!;

print "\n\n==> Finished Cloning Bricolage Database <==\n\n";
exit 0;
