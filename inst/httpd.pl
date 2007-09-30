#!/usr/bin/perl -w

=head1 NAME

httpd.pl - Apache selection script to choose Apache version (apache, apache2)
and start the appropriate probing script

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$LastChangedDate: 2006-06-14 13:30:10 +0200 (Wed, 14 Jun 2006) $

=head1 DESCRIPTION

This script is called during "make" to ask the user to choose between
different Apache versions then start the appropriate probing script.  It
accomplishes this by asking the user .  Output collected in
"httpd.db" by the actual probing scripts.

=head1 AUTHOR

Scott Lanning <slanning@cpan.org>

derived from code by Andrei Arsu <acidburn@asynet.ro>

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

update_required_mods();
run_probe();
exit();

sub update_required_mods {
    our $MOD;
    my $moddb = './modules.db';
    do $moddb or die "Failed to read $moddb: $!";

    my @MOD;
    if ($REQ->{HTTPD_VERSION} eq 'apache') {
        # remove modules not appropriate for apache 1.3
        @MOD = grep { ! /^Apache2/ } @$MOD;
    }
    elsif ($REQ->{HTTPD_VERSION} eq 'apache2') {
        # xxx: dunno...
        # @MOD = grep {  } @$MOD;
    }

    open(my $fh, "> $moddb") or die "Unable to open $moddb: $!";
    print $fh Data::Dumper->Dump([\@MOD], ['MOD']);
    close($fh);
}

sub run_probe {
    my $script = "./inst/htprobe_$REQ->{HTTPD_VERSION}.pl";
    # @ARGV might contain "QUIET"
    system($Config{perlpath}, $script, @ARGV) == 0
      or die "Failed to launch $REQ->{HTTPD_VERSION} probing script $script: $?";
}
