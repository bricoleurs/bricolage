#!/usr/bin/perl -w

=head1 Name

database.pl - Probes for the selected database server

=head1 Description

This script is called during C<make> to probe for the selected databse server
by executing the appropriate script, one of:

=over

=item * inst/dbprobe_Pg.pl

=item * inst/dbprobe_mysql.pl

=back

This script is dependent on the existence of F<required.db> to know which
database has been selected.

=head1 Author

Andrei Arsu <acidburn@asynet.ro>

=head1 See Also

L<Bric::Admin>

=cut

use strict;
use File::Spec::Functions;

our $REQ;
do "./required.db" or die "Failed to read required.db : $!";

my $script = catfile 'inst', "dbprobe_$REQ->{DB_TYPE}.pl";
# @ARGV might contain "QUIET"
system($^X, $script, @ARGV)
    and die "Failed to launch $REQ->{DB_TYPE} probing script $script: $?\n";

