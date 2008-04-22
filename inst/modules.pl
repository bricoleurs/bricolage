#!/usr/bin/perl -w

=head1 NAME

modules.pl - installation script to probe for required Perl modules

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$LastChangedDate$

=head1 DESCRIPTION

This script is called during "make" to probe for required Perl
modules.  Output collected in "modules.db" for use by cpan.pl during
"make install".

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

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
my $QUIET = ($ARGV[0] and $ARGV[0] eq 'QUIET') || $ENV{DEVELOPER};

our $REQ;
do './required.db' or die "Failed to read required.db : $!";

print "\n\n==> Probing Required Perl Modules <==\n\n";

our @MOD;
our $MISSING = 0;

# get module list from Bric::Admin
extract_module_list();

# loop through modules, checking existence and versions
foreach my $rec (@MOD) {
    $rec->{found} = check_module($rec);
    unless ($rec->{found}) {
        # If the module is optional, ask if they want to install it;
        # if not, but it's required for their type of installation
        # (i.e. Pg or mysql), treat it as missing anyway.
        if ($rec->{optional} and
            (not ask_yesno("Do you want to install the optional module " .
                           "$rec->{name}?", 0, $QUIET)
               or $rec->{name} ne 'DBD::'.$REQ->{DB_TYPE})) {
            $rec->{found} = 1;
        } else {
            $MISSING = 1;
        }
    }
}

# if we have missing, tell all about it and make sure they want to proceed
if ($MISSING) {
    print "\nThe following required modules are either missing or out of ", 
      "date:\n\n";
    print map { "\t$_->{name}\n" } grep { not $_->{found} } @MOD;
    print <<END;

These modules will be automatically downloaded and installed using
CPAN.pm during "make install".  If this is what you want, press return
or enter "yes" below.  If not, enter "no" and install the modules
above before running "make" again.

END

    # for some reason an "exit 1" here doesn't stop the make run.
    kill(2, $$) unless ask_yesno("Continue?", 1, $QUIET);
}


# all done, dump out module database, announce success and exit
open(OUT, ">modules.db") or die "Unable to open modules.db : $!";
print OUT Data::Dumper->Dump([\@MOD],['MOD']);
close OUT;

print "\n\n==> Finished Probing Required Perl Modules <==\n\n";
exit 0;

# check for an individual module by name and, if specified, version
sub check_module {
    my $rec = shift;
    my $name = $rec->{name};
    my $req_version = $rec->{req_version};

    $|++;
    print "Looking for $name...";

    { 
        local $^W = 0; # ignore warnings from modules
        my $result = eval "require $name;";
        return soft_fail("not found.") if $@;
        print "found.\n";
    }

    if (defined $req_version) {
	print "Checking that $name version is >= $req_version... ";
        local $^W = 0;
	eval { $name->VERSION($req_version) };
	return soft_fail("not ok.") if $@;
	print "ok.\n";
    }

    return 1;
}

# extract the module list from Bric::Admin
sub extract_module_list {
  my @mod;
  open(ADM, "$FindBin::Bin/../lib/Bric/Admin.pod")
    or die "Unable to open $FindBin::Bin/../lib/Bric/Admin.pod : $!";
  # seek to start of modules
  while (<ADM>) {
    last if /START MODULE LIST/;
  }
  # read in modules
  while (<ADM>) {
    if (/^=item\s+(\S+)(?:\s+([\d\.]+))?(?:\s+(\(optional\)))?/) {
      push @MOD, { name             => $1,
		   req_version      => $2,
                   optional         => defined $3 ? 1 : 0,
                 };
    } elsif (/END MODULE LIST/) {
      last;
    }
  }
  close ADM;
}

