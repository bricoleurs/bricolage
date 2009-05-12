#!/usr/bin/perl -w

=head1 Name

stop.pl - upgrade script to stop running Bricolage servers

=head1 Description

This script is called by "make upgrade" to stop running servers.  Also
cleans out the Bricolage temp space since this has to be done after
the servers are stopped.

=head1 Author

Sam Tregar <stregar@about-inc.com>

=head1 See Also

L<Bric::Admin>

=cut

use strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use Bric::Inst qw(:all);
use File::Spec::Functions qw(:ALL);
use Data::Dumper;

our $CONFIG;
do "./config.db" or die "Failed to read config.db : $!";
our $UPGRADE;
do "./upgrade.db" or die "Failed to read upgrade.db : $!";

print "\n\n==> Stopping Bricolage Servers <==\n\n";

# setup environment to ensure scripts run correctly
$ENV{BRICOLAGE_ROOT} = $UPGRADE->{BRICOLAGE_ROOT};

print "Stopping Bricolage Apache...\n";
system(catfile($CONFIG->{BIN_DIR}, "bric_apachectl"), "stop");

print "Clearing temp space in $CONFIG->{TEMP_DIR}/bricolage...\n";
system("rm", "-rf", catdir($CONFIG->{TEMP_DIR}, "bricolage"));

print "\n\n==> Finished Stopping Bricolage Servers <==\n\n";
