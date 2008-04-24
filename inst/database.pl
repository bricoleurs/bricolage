#!/usr/bin/perl -w

=head1 NAME

database.pl - database selection script to choose database (mysql, postgresql) and
start the appropriate probing script

=head1 DESCRIPTION

This script is called during "make" to ask the user to choose between
different databases then start the appropriate probing script.  It
accomplishes this by asking the user .  Output collected in
"database.db" by the actual probing scripts.

=head1 AUTHOR

Andrei Arsu <acidburn@asynet.ro>

=head1 SEE ALSO

L<Bric::Admin>

=cut

use strict;
use Config;
use FindBin;
use lib "$FindBin::Bin/lib";
use Bric::Inst qw(:all);
use File::Spec::Functions;
use Data::Dumper;


our $REQ;
do "./required.db" or die "Failed to read required.db : $!";

set_required_mod();
run_probe();
exit();

sub run_probe {
    my $script = "./inst/dbprobe_$REQ->{DB_TYPE}.pl";
    # @ARGV might contain "QUIET"
    system($Config{perlpath}, $script, @ARGV) == 0
      or die "Failed to launch $REQ->{DB_TYPE} probing script $script: $?";
}

sub set_required_mod {
    our $MOD;
    do "./modules.db" or die "Failed to read modules.db : $!";

    my @MOD;
    for my $i (0 .. $#$MOD) {
	push @MOD , $MOD->[$i] if !($MOD->[$i]{name}=~/DBD::/);
	push @MOD , $MOD->[$i] if $MOD->[$i]{name}=~/DBD::$REQ->{DB_TYPE}/
    }

    open(OUT, ">modules.db") or die "Unable to open modules.db : $!";
    print OUT Data::Dumper->Dump([\@MOD],['MOD']);
    close OUT;
}
