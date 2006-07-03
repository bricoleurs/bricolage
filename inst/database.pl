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
shift if $QUIET or $ARGV[0] eq 'STANDARD';

print "\n\n==> Selecting Database <==\n\n";

our %DB;
our %DBPROBES;

# setup some defaults
$DB{db}   = get_default("DATABASE") || 'Pg';

our $REQ;
do "./required.db" or die "Failed to read required.db : $!";

our @MOD;
our $MOD;


get_probes();
get_database();


# all done, dump out apache database, require apropriate DBD:: package
# announce success, launch apropriate probe script,and exit
open(OUT, ">database.db") or die "Unable to open database.db : $!";
print OUT Data::Dumper->Dump([\%DB],['DB']);
close OUT;

set_required_mod();

print "\n\n==> Finished Selecting Database <==\n\n";

run_dbscript();

exit 0;


# ask the user to choose a database
sub get_database {
    my $dbstring;
    $dbstring=join(', ',keys(%DBPROBES));
    print "\n";
    ask_confirm("Database ($dbstring): ", \$DB{db}, $QUIET);
}

sub get_probes {
    my $temp1;
    my $temp2;

    while (@ARGV) {
        $temp1=$temp2=shift @ARGV;
        $temp1=~s/inst\/dbprobe_//;
        $temp1=~s/.pl//;
        $DBPROBES{$temp1}=$temp2;
    }
}

sub run_dbscript {
    my $dbscript=$DBPROBES{$DB{db}};
    $dbscript = $dbscript." ".$QUIET if $QUIET;
    do $dbscript;
    do $dbscript or die "Failed to launch $DB{db} probing script $dbscript";
}

sub set_required_mod {
    do "./modules.db" or die "Failed to read modules.db : $!";
    for my $i (0 .. $#$MOD) {
#	print "\ntest=$MOD->[$i]{name}";
	push @MOD , $MOD->[$i] if !($MOD->[$i]{name}=~/DBD::/);
	push @MOD , $MOD->[$i] if $MOD->[$i]{name}=~/DBD::$DB{db}/
    }

    open(OUT, ">modules.db") or die "Unable to open modules.db : $!";
    print OUT Data::Dumper->Dump([\@MOD],['MOD']);
    close OUT;
}
