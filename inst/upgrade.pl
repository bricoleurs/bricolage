#!/usr/bin/perl -w

=head1 Name

upgrade.pl - installation script to gather upgrade information

=head1 Description

This script is called by "make upgrade" to prepare for an upgrade.
Gathers configuration information from the user and install.db if
available.  Outputs to the various .db files used by later stages of
the install.

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
use lib './lib'; # To get local version number.

# make sure we're root, otherwise uninformative errors result
unless ($> == 0) {
    print "This process must (usually) be run as root.\n";
    exit 1 unless ask_yesno("Continue as non-root user?", 1);
}

# setup default root
our %UPGRADE = (
    BRICOLAGE_ROOT => $ENV{BRICOLAGE_ROOT} || '/usr/local/bricolage'
);
our ($INSTALL, %DB,$DB,%PG);

print q{
##########################################################################

  We strongly recommend that you `make clone` your existing installation
  (using the sources for that version ) BEFORE running `make upgrade`.
  This is so that if there are any problems with the upgrade, you can
  delete the installation, install the clone, fix the problems, and then
  try `make upgrade` again.

##########################################################################

};

exit 1 unless ask_yesno("Continue with the upgrade?", 1);

print "\n\n==> Setting-up Bricolage Upgrade Process <==\n\n";

get_bricolage_root();
read_install_db();
check_version();
confirm_paths();
modify_vars();
output_dbs();

print "\n\n==> Finished Setting-up Bricolage Upgrade Process <==\n\n";

# find the bricolage to update
sub get_bricolage_root {
    ask_confirm(
        'Bricolage Root Directory to Upgrade?',
        \$UPGRADE{BRICOLAGE_ROOT}
    );

    # verify that we have a Bricolage install here
    hard_fail("No Bricolage installation found in $UPGRADE{BRICOLAGE_ROOT}.\n")
        unless -e catfile($UPGRADE{BRICOLAGE_ROOT}, 'conf', 'bricolage.conf');

    # verify that this Bricolage was installed with "make install"
    hard_fail(
        "The Bricolage Installation found in $UPGRADE{BRICOLAGE_ROOT}\n",
        "was installed manually and cannot be automatically upgraded."
    ) unless -e catfile($UPGRADE{BRICOLAGE_ROOT}, 'conf', 'install.db');
    $ENV{BRICOLAGE_ROOT} = $UPGRADE{BRICOLAGE_ROOT};
}

# read the install.db file from the chosen bricolage root
sub read_install_db {
    my $install_file = catfile($UPGRADE{BRICOLAGE_ROOT}, 'conf', 'install.db');
    if (-e $install_file) {
        # read it in if it exists
        do $install_file or die "Failed to read $install_file: $!\n";
    }
}

# check that the version number exists in the version database, note
# the versions need to upgrade to current version
sub check_version {
    my @todo;

    # determine version being installed (Only after BRICOLAGE_ROOT has been
    # set up so that bricolage.conf is properly read-in.
    require Bric;
    my $VERSION = Bric->VERSION;

    # make sure we're not trying to install the same version twice
    if ($INSTALL->{VERSION} eq $VERSION) {
        print <<END;
The installed version ("$VERSION") is the same as this version!
`make upgrade` is only designed to work to upgrade from one version
to another. Please use `make install` if you wish to overwrite your
current install.

END
        exit 1 unless ask_yesno('Continue with upgrade?', 0);
        @todo = ($VERSION);

    } else {
        # read in versions.txt
        my @versions;
        open VER, 'inst/versions.txt'
            or die "Cannot open inst/versions.txt : $!";
        while (<VER>) {
            chomp;
            next if /^#/ or /^\s*$/;
            push @versions, $_;
        }
        close VER;

        # find this version
        my $found;
        for my $i (0 .. $#versions) {
            if ($versions[$i] eq $INSTALL->{VERSION}) {
                $found = 1;
                @todo = @versions[$i + 1 .. $#versions];
                last;
            }
        }

        # didn't find the version?
        hard_fail(<<END) unless $found;
Couldn't find version "$INSTALL->{VERSION}" in inst/versions.txt.  Are
you trying to install an older version over a newer one?  That won't
work.
END
    }

    # save todo list for later
    $UPGRADE{TODO} = \@todo;

    # note the plan of action
    print "Found existing version $INSTALL->{VERSION}.\n";
    print 'Will run database upgrade scripts for version(s) ',
        join(', ', @todo), "\n" if @todo;
}

# confirm paths listed in install.db
sub confirm_paths {
    print "\nPlease confirm the Bricolage target directories.\n\n";
    ask_confirm(
        'Bricolage Perl Module Directory',
        \$INSTALL->{CONFIG}{MODULE_DIR}
    );
    ask_confirm(
        'Bricolage Executable Directory',
        \$INSTALL->{CONFIG}{BIN_DIR}
    );
    ask_confirm(
        'Bricolage Man-Page Directory (! to skip)',
        \$INSTALL->{CONFIG}{MAN_DIR}
    );
    ask_confirm(
        'Mason Component Directory',
        \$INSTALL->{CONFIG}{MASON_COMP_ROOT}
    );
}

# modify_vars makes small changes to variables names introduced in 1.11.0
sub modify_vars {
    my ($x, $y, $z) = $INSTALL->{VERSION} =~ /(\d+)\.(\d+)(?:\.(\d+))?/;
    if (($x < 1) or ($x == 1 and $y < 11)) {
        %DB = %PG;
        $DB->{db_type} = 'Pg';
        $DB->{exec} = $DB->{psql};
    }
}

# output .db files used by installation steps
sub output_dbs {
    # fake up the .dbs from %INSTALL
    my %dbs = (
        DB     => 'database.db',
        CONFIG => 'config.db',
        AP     => 'apache.db',
        REQ    => 'installed.db',
    );
    while ( my ($key, $file) = each %dbs) {
        # We must have a version number for th database.
        next if $key eq 'DB' && !$INSTALL->{$key}{version};
        open FILE, ">$file" or die "Unable to open $file: $!\n";
        print FILE Data::Dumper->Dump([$INSTALL->{$key}], [$key]);
        close FILE;
    }

    # output upgrade.db
    open FILE, ">upgrade.db" or die "Unable to open upgrade.db: $!\n";
    print FILE Data::Dumper->Dump([\%UPGRADE], ["UPGRADE"]);
    close(FILE);
}
