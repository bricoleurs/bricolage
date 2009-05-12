#!/usr/bin/perl -w

=head1 Name

cpan.pl - installation script to install CPAN modules

=head1 Description

This script is called during "make install" to install Perl modules
from CPAN.

=head1 Author

Sam Tregar <stregar@about-inc.com>

=head1 See Also

L<Bric::Admin>

=cut

use strict;
use File::Spec::Functions qw(:ALL);
use Cwd;

our $MOD;
my $perl;
my $cwd;

BEGIN { $perl = $ENV{PERL} || $^X }

BEGIN {
    # Figure out where we are.
    $cwd = getcwd;
    # read in list of required modules
    do "./modules.db" or die "Failed to read modules.db : $!";
    # See if we need to install any modules.
    my $need;
    for my $i (0 .. $#$MOD) {
        next if $MOD->[$i]{found};
        $need = 1;
        last;
    }
    unless ($need) {
        # Don't need to install any, no need to run CPAN.pm.
        print "All modules installed. No need to install from CPAN.\n";
        exit;
    }

    # try to figure out if CPAN.pm has been configured.  This mimics
    # the logic in CPAN.pm.  If this turns out not to be reliable
    # another possibility would be to just `perl -MCPAN -e shell` and
    # look for the "configuration required" text.
    my $found_config = 0;
    eval { require CPAN::Config };
    $found_config = 1 unless $@;
    unshift(@INC, catdir($ENV{HOME}, '.cpan'));
    eval { require CPAN::MyConfig };
    $found_config = 1 unless $@;
    shift(@INC);

    unless ($found_config) {
    print "#" x 79, "\n\n", <<END, "\n", "#" x 79, "\n";
This installation system uses CPAN.pm to automatically install CPAN
modules.  I have detected that you have never used CPAN.pm to install
Perl modules.  Before I can proceed with this installation you must
configure the CPAN.pm module.  To do this, type the following command
as root:

  $perl -MCPAN -e shell

You will be presented with a series of questions.  At the end you will
be at a "cpan>" prompt.  Next, you should install the latest CPAN.pm:

  install CPAN

After this step you should quit the CPAN shell and run it one more
time to be certain it works.  You may need to re-answer the CPAN.pm
questionnaire at this time.  Once you have a working CPAN.pm come back
here are re-run "make install".

END
    exit 1;
    }
}

use Cwd;
use FindBin;
use lib "$FindBin::Bin/lib";
use Bric::Inst qw(:all);
use Data::Dumper;
use Config;
use CPAN;

# make sure this is a recent version of CPAN.pm.  The stuff we're doing
# below is dependent on some recent fixes.
{
    no warnings; # avoid blabber about "1.59_54" not being numeric
    hard_fail(<<END) unless $CPAN::VERSION >= 1.59;
CPAN.pm version 1.59 or greater required.  Please update your CPAN
installation using the command (as root):

  $perl -MCPAN -e 'install CPAN'

After this step you should quit the CPAN shell and run it one more
time to be certain it works.  You may need to re-answer the CPAN.pm
questionnaire at this time.  Once you have a working CPAN.pm come back
here are re-run "make install".
END
}

# make sure we're root, otherwise uninformative errors result
unless ($> == 0) {
    print "This process must (usually) be run as root.\n";
    exit 1 unless ask_yesno("Continue as non-root user? ", 1);
}

$|++;
print "\n\n==> Installing Modules From CPAN <==\n\n";

# setup flags for modules that need extra help to install
use constant FORCE  => 1;
use constant PG_ENV => 2;
our %flags = (
          'Net::Cmd'         => FORCE,
          'LWP'              => FORCE,
          'XML::Writer'      => FORCE,
          'Params::Validate' => FORCE,
          'DBD::Pg'          => FORCE|PG_ENV,
          'Cache::Cache'     => FORCE,
          'HTML::Mason'      => FORCE,
         );

our $DB;
do "./database.db" or die "Failed to read database.db : $!";

# loop through modules installing as we go
for my $i (0 .. $#$MOD) {
    next if $MOD->[$i]{found};

    install_module($MOD->[$i]{name}, $MOD->[$i]{req_version});
    $MOD->[$i]{found} = 1;

    # make sure we don't redo this work, even if we're run twice in a
    # row after a failure.
    update_modules_db();
}

print "\n\n==> Finished Installing Modules From CPAN <==\n\n";

exit 0;

# installs a single module from CPAN, following dependencies
sub install_module {
    my ($name, $req_version) = @_;

    # push onto the queue.  This keeps everything simpler below
    if ( CPAN::Queue->can('new') ) {
        CPAN::Queue->new( $name );
    } else {
        CPAN::Queue->queue_item( qmod => $name, reqtype => 'r' );
    }

    # process the queue
    while (my $q = CPAN::Queue->first) {
        # get a module object one way or another
        my $s = ref $q && $q->can('as_string')
            ? $q->as_string
            : ref $q ? $q->id : $q;
        my $m = $q->can('as_string')
            ? CPAN::Shell->expandany($s)
            : ref $q ? $q : CPAN::Shell->expandany($q);
        hard_fail(<<END) unless $m;
Could not find $s on CPAN. Your CPAN.pm installation
may be broken. To debug manually, run:

  $perl -MCPAN -e 'install $s'
END

        print "Found $s  Installing...\n";

        # If dependencies were pushed in front of this module, undelay it
        # so that it can now proceed.
        $m->undelay;

        # get name of module being installed
        my $key = $m->isa('CPAN::Distribution') ? $m->called_for : $s;

        # for some reason that doesn't work for HTML::Mason
        $key = 'HTML::Mason' unless defined $key;

        # sometimes I used a little too much force
        $m->force('install') if $flags{$key} and $flags{$key} & FORCE;

        # need PG env vars?
        if ($flags{$key} and $flags{$key} & PG_ENV) {
            $ENV{POSTGRES_INCLUDE} = $DB->{include_dir};
            $ENV{POSTGRES_LIB}     = $DB->{lib_dir};
        }

        # do the install. If prereqs are found they'll get put on the Queue
        # and processed in turn.
        print "Install\n";
        $m->install;
        if (
            ($m->can('uptodate') ? $m->uptodate : 0)      # It's up-to-date
            or ($m->{install} && $m->{install} eq 'YES')  # It was installed
        ) {
            # Done with that module!
            print "Done\n";
        } elsif (CPAN::Queue->first ne $q) {
            # Prereqs need to be satisified.
            next;
        } else {
            # Something's fucked up.
            exit 1;
        }

        if ($req_version && $m->can('inst_version')) {
            # check to make sure it worked
            print "Checking $name installation...\n";
            my $inst = $m->inst_version or return undef;
            local $^W = 0;
            require CPAN::Version unless CPAN::Version->can('vcmp');
            hard_fail(fail_msg( $perl, $name, $req_version))
                unless CPAN::Version->vcmp( $inst, $req_version ) >= 0;
        }

        # remove self from the queue
        CPAN::Queue->delete_first($s);
    }

    # all done.
    print "$name installed successfully.\n";
}

sub fail_msg {
    my ($perl, $name, $req_version);
     <<END
Installation of $name version $req_version failed. Your
CPAN.pm installation may be broken. To debug manually,
run (as root):

  $perl -MCPAN -e shell

Then at the "cpan>" prompt:

  look $name

You can then attempt to install the module manually with:

  $perl Makefile.PL
  make test
  make install

END
}

# updates modules.db with progress
sub update_modules_db {
    # update modules database with progress
    chdir $cwd;
    open(OUT, ">modules.db") or die "Unable to open modules.db : $!";
    print OUT Data::Dumper->Dump([$MOD],['MOD']);
    close OUT;
}
