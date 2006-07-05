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



our @MOD;
our $MOD;

# check whether questions should be asked
our $QUIET;
$QUIET = 1 if $ARGV[0] and $ARGV[0] eq 'QUIET';

our $REQ;
do "./required.db" or die "Failed to read required.db : $!";

set_required_mod();
run_dbscript();

exit 0;

sub run_dbscript {
    my $dbscript="./inst/dbprobe_".$REQ->{DB_TYPE}.".pl";
    $dbscript = $dbscript." ".$QUIET if $QUIET;
    do $dbscript;
    do $dbscript or die "Failed to launch $REQ->{DB_TYPE} probing script $dbscript";
}

sub set_required_mod {
    do "./modules.db" or die "Failed to read modules.db : $!";
    for my $i (0 .. $#$MOD) {
#	print "\ntest=$MOD->[$i]{name}";
	push @MOD , $MOD->[$i] if !($MOD->[$i]{name}=~/DBD::/);
	push @MOD , $MOD->[$i] if $MOD->[$i]{name}=~/DBD::$REQ->{DB_TYPE}/
    }

    open(OUT, ">modules.db") or die "Unable to open modules.db : $!";
    print OUT Data::Dumper->Dump([\@MOD],['MOD']);
    close OUT;
}
