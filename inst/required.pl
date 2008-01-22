#!/usr/bin/perl -w

=head1 NAME

required.pl - installation script to probe for required software

=head1 VERSION

$LastChangedRevision$

=head1 DATE

$LastChangedDate$

=head1 DESCRIPTION

This script is called during "make" to probe for required software -
Perl, Apache, Postgres, and Expat currently.  Output collected
in "required.db".

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

=head1 SEE ALSO

L<Bric::Admin>

=cut


use strict;

# check required Perl version first, fail immediately if too old
BEGIN {
    eval { require 5.008 };
    if ($@) {
        print "#" x 79, "\n\n", <<END, "\n", "#" x 79, "\n";
Bricolage requires Perl version 5.8.0 or later. Please upgrade your version
of Perl before re-running make. You can find the latest versions of Perl at
'http://perl.com/'.

END
        exit 1;
    }
}

use FindBin;
use lib "$FindBin::Bin/lib";
use Bric::Inst qw(:all);
use File::Spec::Functions;
use Data::Dumper;
use Config;

our %REQ;
our %RESULTS;

# check to see whether we should ask questions or not
our $QUIET;
$QUIET = 1 if $ARGV[0] and $ARGV[0] eq 'QUIET';

# collect data - configuration requirements data goes into %REQ, raw
# binary pass/fail goes into %RESULTS.

print "\n\n==> Probing Required Software <==\n\n";

# run tests
$RESULTS{PG}      = find_pg();
$RESULTS{APACHE}  = find_apache();
$RESULTS{EXPAT}   = find_expat();

# print error message and fail if something not found
unless ($RESULTS{PG} and $RESULTS{APACHE} and
        $RESULTS{EXPAT}) {
  hard_fail("Required software not found:\n\n",
            $RESULTS{PG}     ? "" :
            "\tPostgreSQL >= 7.3.0 (http://postgresql.org)\n",
            $RESULTS{APACHE} ? "" :
            "\tApache >= 1.3.12    (http://apache.org)\n",
            $RESULTS{EXPAT}  ? "" :
            "\texpat >= 1.95.0     (http://expat.sourceforge.net)\n",
            "\nSee INSTALL for details.\n"
           );
}

# success, write out %REQ hash into required.db
open(OUT, ">required.db") or die "Unable to open required.db : $!";
print OUT Data::Dumper->Dump([\%REQ],['REQ']);
close OUT;

# all done
print "\n\n==> Finished Probing Required Software <==\n\n";
exit 0;

# look for postgresql
sub find_pg {
    print "Looking for PostgreSQL with version >= 7.3.0...\n";

    # find PostgreSQL by looking for pg_config.
    my @paths = (split(", ", get_default("PG_CONFIG_PATH")), path);
    foreach my $path (@paths) {
    if (-e catfile($path, "pg_config")) {
        $REQ{PG_CONFIG} = catfile($path, "pg_config");
        last;
    }
    }

    # confirm or deny
    if ($REQ{PG_CONFIG}) {
        print "Found PostgreSQL's pg_config at '$REQ{PG_CONFIG}'.\n";
        unless (ask_yesno("Is this correct?", 1, $QUIET)) {
            ask_confirm("Enter path to pg_config", \$REQ{PG_CONFIG});
        }
    } else {
        print "Failed to find pg_config.\n";
        if (ask_yesno("Do you want to provide a path to pg_config?", 0, $QUIET)) {
            $REQ{PG_CONFIG} = 'NONE';
            ask_confirm("Enter path to pg_config", \$REQ{PG_CONFIG});
        } else {
            return soft_fail("Failed to find pg_config. Looked in:",
                             map { "\n\t$_" } @paths);
        }
    }

    # check version
    my $version = `$REQ{PG_CONFIG} --version`;
    return soft_fail("Failed to find PostgreSQL version with ",
                     "`$REQ{PG_CONFIG} --version`.") unless $version;
    chomp $version;
    my ($x, $y, $z) = $version =~ /(\d+)\.(\d+)(?:\.(\d+))?/;
    return soft_fail("Failed to parse PostgreSQL version from string ",
                     "\"$version\".") 
        unless defined $x and defined $y;
    $z ||= 0;
    return soft_fail("Found old version of Postgres: $x.$y.$z - ",
                     "7.3.0 or greater required.")
        unless (($x > 7) or ($x == 7 and $y >= 3));
    print "Found acceptable version of Postgres: $x.$y.$z.\n";

    $REQ{PG_VERSION} = [$x,$y,$z];

    return 1;
}

# look for apache
sub find_apache {
    print "Looking for Apache with version >= 1.3.12...\n";

    # find Apache by looking for executables called httpd, httpsd,
    # apache-perl or apache, in that order.  First search user's
    # path then some standard locations.
    my @paths = (split(", ", get_default("APACHE_PATH")), path);
    my @exe = (split(", ", get_default("APACHE_EXE")));

 FIND:
    foreach my $exe (@exe) {
        foreach my $path (@paths) {
            if (-e catfile($path, $exe)) {
                $REQ{APACHE_EXE} = catfile($path, $exe);
                last FIND;
            }
        }
    }

    # confirm or deny
    if ($REQ{APACHE_EXE}) {
        print "Found Apache server binary at '$REQ{APACHE_EXE}'.\n";
        unless ($QUIET or ask_yesno("Is this correct?", 1)) {
            ask_confirm("Enter path to Apache server binary",
                        \$REQ{APACHE_EXE});
        }
    } else {
        print "Failed to find Apache server binary.\n";
        if (ask_yesno("Do you want to provide a path to the Apache server " .
                      "binary?", 0, $QUIET)) {
            $REQ{APACHE_EXE} = 'NONE';
            ask_confirm("Enter path to Apache server binary",
                        \$REQ{APACHE_EXE});
        } else {
            return soft_fail("Failed to find Apache executable. Looked for ",
                             join(', ', @exe),
                             " in:",
                             map { "\n\t$_" } @paths);
        }
    }

    print "Found Apache executable at $REQ{APACHE_EXE}.\n";

    # check version
    my $version = `$REQ{APACHE_EXE} -v`;
    return soft_fail("Failed to find Apache version with ",
                     "`$REQ{APACHE_EXE} -v`.") unless $version;
    chomp $version;
    my ($x, $y, $z) = $version =~ /(\d+)\.(\d+).(\d+)/;
    return soft_fail("Failed to parse Apache version from string ",
                     "\"$version\".") 
        unless defined $x and defined $y and defined $z;
    return soft_fail("Found Apache 2. Bricolage only supports Apache 1.3.\n")
      if $x > 1;
    return soft_fail("Found old version of Apache: $x.$y.$z - ",
                     "1.3.12 or greater required.")
        unless (($x == 1 and $y > 3) or ($x == 1 and $y == 3 and $z >= 12));
    print "Found acceptable version of Apache: $x.$y.$z.\n";
    $REQ{APACHE_VERSION} = [$x,$y,$z];

    return 1;
}

# look for Expat
sub find_expat {
    print "Looking for expat...\n";

    # find expat libary libexpat.so by looking in library paths that
    # Perl knows about
    my @paths = grep { defined and length } ( split(' ', $Config{libsdirs}),
                                              split(' ', $Config{loclibpth}),
                                              split(' ', $Config{loclibpth}));
    push @paths, split(", ", get_default("EXPAT_PATH"));

    my @files = split(", ", get_default("EXPAT_FILE"));

  LOOK: foreach my $path (@paths) {
        foreach my $file(@files) {
            if (-e catfile($path, $file)) {
                $REQ{EXPAT} = catfile($path, "libexpat.so");
                last LOOK;
            }
        }
    }
    return soft_fail("Failed to find libexpat.so. Looked in:",
                     map { "\n\t$_" } @paths) unless $REQ{EXPAT};
    print "Found expat at $REQ{EXPAT}.\n";

    # I should check that expat is >= 1.95.0.  Um, how do I do that?

    return 1;
}
