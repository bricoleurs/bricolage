#!/usr/bin/perl -w

=head1 Name

database.pl - Probes for the selected Apache server

=head1 Description

This script is called during C<make> to probe for the selected databse server
by executing the appropriate script, one of:

=over

=item * inst/htprobe_apache.pl

=item * inst/htprobe_apache2.pl

=back

This script is dependent on the existence of F<required.db> to know which
Apache has been selected.

=head1 Author

Scott Lanning <slanning@cpan.org>

derived from code by Andrei Arsu <acidburn@asynet.ro>

=head1 See Also

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
do './required.db' or die "Failed to read required.db: $!\n";

my $script = catfile 'inst', "htprobe_$REQ->{HTTPD_VERSION}.pl";
# @ARGV might contain "QUIET"
system($^X, $script, @ARGV)
    and die "Failed to launch $REQ->{HTTPD_VERSION} probing script $script: $?\n";
