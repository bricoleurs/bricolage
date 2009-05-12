#!/usr/bin/perl -w

=head1 Name

uninstall.pl - installation script to uninstall Bricolage

=head1 Description

This script is called by "make uninstall" to uninstall Bricolage.
It removes all installed modules, binaries, components, and the
database. It gathers configuration information from the user and
install.db if available. This is mostly copied from upgrade.pl.

=head1 Author

Sam Tregar <stregar@about-inc.com>

Scott Lanning <slanning@theworld.com>

=head1 See Also

L<Bric::Admin>

=cut

use strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use Bric::Inst qw(:all);
use File::Spec::Functions qw(:ALL);
use Data::Dumper;

# make sure we're root, otherwise uninformative errors result
unless ($> == 0) {
    print "This process must (usually) be run as root.\n";
    exit 1 unless ask_yesno("Continue as non-root user?", 1);
}

# setup default root
# (XXX: same variable name (%UPGRADE) as upgrade.pl
#  so that stop.pl will work as is)
our %UPGRADE = ( BRICOLAGE_ROOT => $ENV{BRICOLAGE_ROOT} ||
                           '/usr/local/bricolage' );
our $INSTALL;

print "\n\n==> Setting-up Bricolage Uninstall Process <==\n\n";

get_bricolage_root();
read_install_db();
output_dbs();

print "\n\n==> Finished Setting-up Bricolage Uninstall Process <==\n\n";

# find the bricolage to update
sub get_bricolage_root {
    ask_confirm("Bricolage Root Directory to Uninstall?",
        \$UPGRADE{BRICOLAGE_ROOT});

    # verify that we have a Bricolage install here
    hard_fail("No Bricolage installation found in $UPGRADE{BRICOLAGE_ROOT}.\n")
    unless -e catfile($UPGRADE{BRICOLAGE_ROOT}, "conf", "bricolage.conf");

    # verify that this Bricolage was installed with "make install"
    hard_fail("The Bricolage Installation found in $UPGRADE{BRICOLAGE_ROOT}\n",
          "was installed manually and cannot be automatically uninstalled.")
    unless -e catfile($UPGRADE{BRICOLAGE_ROOT}, "conf", "install.db");
}

# read the install.db file from the chosen bricolage root
sub read_install_db {
    my $install_file = catfile($UPGRADE{BRICOLAGE_ROOT}, "conf", "install.db");
    if (-e $install_file) {
    # read it in if it exists
    do $install_file or die "Failed to read $install_file : $!";
    }
}

# output .db files used by installation steps
# (XXX: config.db and upgrade.db must be output for stop.pl to work as is)
sub output_dbs {
    # fake up the .dbs from %INSTALL
    my %dbs = (
        DB     => 'database.db',
        CONFIG => 'config.db',
    );
    while ( my ($key, $file) = each %dbs) {
        open(FILE, ">$file") or die "Unable to open $file : $!\n";
        print FILE Data::Dumper->Dump([$INSTALL->{$key}], [$key]);
        close(FILE);
    }

    # output upgrade.db
    open(FILE, '>upgrade.db') or die "Unable to open upgrade.db : $!\n";
    print FILE Data::Dumper->Dump([\%UPGRADE], ['UPGRADE']);
    close(FILE);
}
