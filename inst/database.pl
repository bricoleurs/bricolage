#!/usr/bin/perl -w

=head1 NAME

database.pl - database selection script to choose database (mysql, postgresql) and
start the apropiate probing script

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$LastChangedDate: 2006-06-14 13:30:10 +0200 (Wed, 14 Jun 2006) $

=head1 DESCRIPTION

This script is called during "make" to ask the user to choose between 
different databases then start the apropriate probing script.  It 
accomplishes this by asking the user .  Output collected in
"database.db" by the actual probing scripts.

=head1 AUTHOR

Andrei Arsu <acidburn@asynet.ro>

=head1 SEE ALSO

L<Bric::Admin>

=cut

use strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use Bric::Inst qw(:all);
use File::Spec::Functions;
use Data::Dumper;

# check whether questions should be asked
our $QUIET;
$QUIET = 1 if $ARGV[0] and $ARGV[0] eq 'QUIET';


print "\n\n==> Selecting Database <==\n\n";

our %DB;

# setup some defaults
$DB{db}   = get_default("DATABASE") || 'pg';

our $REQ;
do "./required.db" or die "Failed to read required.db : $!";

get_database();

# all done, dump out apache database, announce success and exit
open(OUT, ">database.db") or die "Unable to open database.db : $!";
print OUT Data::Dumper->Dump([\%DB],['DB']);
close OUT;

print "\n\n==> Finished Selecting Database <==\n\n";
my $instdb;
if ($DB{db} eq 'mysql') {
    $instdb = "./inst/mysql.pl";
    $instdb .=" ".$QUIET if $QUIET;
    do $instdb or die "Failed to launch Mysql probing script";    
    }
else {
    $instdb = "./inst/postgres.pl";
    $instdb .=" ".$QUIET if $QUIET;    
    do $instdb or die "Failed to launch Postgres probing script";
    }

exit 0;


# ask the user to choose a database 
sub get_database {
    print "\n";
    ask_confirm("Database (mysql, pg): ", \$DB{db}, $QUIET);
}

