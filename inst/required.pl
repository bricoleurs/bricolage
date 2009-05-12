#!/usr/bin/perl -w

=head1 Name

required.pl - installation script to probe for required software
and select database and Apache version

=head1 Description

This script is called during "make" to probe for required software -
Perl, Apache/Apache2, PostgreSQL/MySQL, and Expat currently.
Output collected in "required.db".

=head1 Author

Sam Tregar <stregar@about-inc.com>

database selection support added by Andrei Arsu <acidburn@asynet.ro>

apache version support added by Scott Lanning <slanning@cpan.org>

=head1 See Also

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

our (%REQ, %RESULTS, %PROBES);

# check to see whether we should ask questions or not
my $QUIET = ($ARGV[0] and $ARGV[0] eq 'QUIET') || $ENV{DEVELOPER};
shift if $QUIET or $ARGV[0] eq 'STANDARD';

if (-e 'installed.db') {
    # Grab the data for what's already installed (it's an upgrade).
    %REQ = %{ do './installed.db' or die "Failed to read installed.db: $!\n" };
}

# collect data - configuration requirements data go into %REQ,
# boolean pass/fail go into %RESULTS.

# setup some defaults
$REQ{DB_TYPE}       ||= get_default('DB_TYPE')       || 'Pg';
$REQ{HTTPD_VERSION} ||= get_default('HTTPD_VERSION') || 'apache';

get_probes();

print "\n\n==> Probing Required Software <==\n\n";

get_database();
get_httpd();

# run tests
$RESULTS{PG}      = find_pg()      if $REQ{DB_TYPE} eq 'Pg';
$RESULTS{MYSQL}   = find_mysql()   if $REQ{DB_TYPE} eq 'mysql';
$RESULTS{APACHE}  = find_apache()  if $REQ{HTTPD_VERSION} eq 'apache';
$RESULTS{APACHE2} = find_apache2() if $REQ{HTTPD_VERSION} eq 'apache2';
$RESULTS{EXPAT}   = find_expat();

# print error message and fail if something not found
unless (
    ($RESULTS{PG} or $RESULTS{MYSQL})
    and ($RESULTS{APACHE} or $RESULTS{APACHE2})
    and $RESULTS{EXPAT}
) {
    hard_fail(
        "Required software not found:\n\n",
        ($RESULTS{PG} or ($REQ{DB_TYPE} eq 'mysql')) ? '' :
            "\tPostgreSQL >= 7.3.0       (http://postgresql.org)\n",
        ($RESULTS{MYSQL} or ($REQ{DB_TYPE} eq 'Pg')) ? '' :
            "\tMySQL client >= 4.1.0     (http://mysql.com)\n",
        ($RESULTS{APACHE} or ($REQ{HTTPD_VERSION} eq 'apache2')) ? '' :
            "\tApache >= 1.3.34 && < 2.0 (http://httpd.apache.org)\n",
        ($RESULTS{APACHE2} or ($REQ{HTTPD_VERSION} eq 'apache')) ? '' :
            "\tApache >= 2.0.55          (http://httpd.apache.org)\n",
        $RESULTS{EXPAT}   ? '' :
            "\texpat >= 1.95.0           (http://expat.sourceforge.net)\n",
        "\nSee INSTALL for details.\n"
    );
}

# success, write out %REQ hash into required.db
open OUT, '>required.db' or die "Unable to open required.db: $!\n";
print OUT Data::Dumper->Dump([\%REQ],['REQ']);
close OUT;

# all done
print "\n\n==> Finished Probing Required Software <==\n\n";
exit 0;


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
            return soft_fail(
                "Failed to find pg_config. Looked in:",
                map { "\n\t$_" } @paths
            );
        }
    }

    # check version
    my $version = `$REQ{PG_CONFIG} --version`;
    return soft_fail(
        "Failed to find PostgreSQL version with ",
        "`$REQ{PG_CONFIG} --version`."
    ) unless $version;
    chomp $version;
    my ($x, $y, $z) = $version =~ /(\d+)\.(\d+)(?:\.(\d+))?/;
    return soft_fail(
        qq{Failed to parse PostgreSQL version from string "$version".}
    ) unless defined $x and defined $y;
    $z ||= 0;
    return soft_fail(
        "Found old version of Postgres: $x.$y.$z - 7.3.0 or greater required."
    ) unless (($x > 7) or ($x == 7 and $y >= 3));
    print "Found acceptable version of Postgres: $x.$y.$z.\n";

    $REQ{PG_VERSION} = [$x,$y,$z];

    return 1;
}

sub find_mysql {
    print "Looking for MySQL client with version >= 4.1....\n";

    # find MySQL by looking for mysql_config.
    my @paths = (split(", ", get_default("MYSQL_CONFIG_PATH")), path);
    foreach my $path (@paths) {
        if (-e catfile($path, "mysql_config")) {
            $REQ{MYSQL_CONFIG} = catfile($path, "mysql_config");
            last;
        }
    }

    # confirm or deny
    if ($REQ{MYSQL_CONFIG}) {
        print "Found MySQL's mysql_config at '$REQ{MYSQL_CONFIG}'.\n";
        unless (ask_yesno("Is this correct?", 1, $QUIET)) {
            ask_confirm("Enter path to mysql_config", \$REQ{MYSQL_CONFIG});
        }
    } else {
        print "Failed to find mysql_config.\n";
        if (ask_yesno("Do you want to provide a path to mysql_config?", 0, $QUIET)
        ) {
            $REQ{MYSQL_CONFIG} = 'NONE';
            ask_confirm("Enter path to mysql_config", \$REQ{MYSQL_CONFIG});
        } else {
            return soft_fail(
                "Failed to find mysql_config. Looked in:",
                map { "\n\t$_" } @paths
            );
        }
    }

    # check version
    my $version = `$REQ{MYSQL_CONFIG} --version`;
    return soft_fail(
        "Failed to find MysqlSQL version with ",
        "`$REQ{MYSQL_CONFIG} --version`."
    ) unless $version;
    chomp $version;
    my ($x, $y, $z) = $version =~ /(\d+)\.(\d+)(?:\.(\d+))?/;
    return soft_fail(
        qq{Failed to parse MySQL client version from string "$version".}
    ) unless defined $x and defined $y;
    $z ||= 0;
    return soft_fail(
        "Found old version of Mysql client: $x.$y.$z - 5.0.3 or greater required."
    ) unless (
           ($x > 5)
        or ($x == 5 and $y >= 0)
        or ($x == 5 and $y == 0 and $z >= 3)
    );
    print "Found acceptable version of MySQL: $x.$y.$z.\n";

    $REQ{MYSQL_CLIENT_VERSION} = [$x,$y,$z];
    return 1;
}


sub find_apache {
    print "Looking for Apache with version >= 1.3.34 && < 2.0...\n";

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
        print "Found Apache 1.3 server binary at '$REQ{APACHE_EXE}'.\n";
        unless ($QUIET or ask_yesno("Is this correct?", 1)) {
            ask_confirm(
                "Enter path to Apache 1.3 server binary",
                \$REQ{APACHE_EXE}
            );
        }
    } else {
        print "Failed to find Apache server binary.\n";
        if (ask_yesno(
            "Do you want to provide a path to the Apache server binary?",
            0,
            $QUIET
        )) {
            $REQ{APACHE_EXE} = 'NONE';
            ask_confirm(
                "Enter path to Apache server binary",
                \$REQ{APACHE_EXE}
            );
        } else {
            return soft_fail(
                "Failed to find Apache 1.3 executable. Looked for ",
                join(', ', @exe),
                " in:",
                map { "\n\t$_" } @paths
            );
        }
    }

    print "Found Apache 1.3 executable at $REQ{APACHE_EXE}.\n";

    # check version
    my $version = `$REQ{APACHE_EXE} -v`;
    return soft_fail(
        "Failed to find Apache 1.3 version with `$REQ{APACHE_EXE} -v`."
    ) unless $version;
    chomp $version;
    my ($x, $y, $z) = $version =~ /(\d+)\.(\d+).(\d+)/;
    return soft_fail(
        qq{Failed to parse Apache 1.3 version from string "$version".}
    ) unless defined $x and defined $y and defined $z;

    return soft_fail(
        "Found unacceptable version of Apache: $x.$y.$z - ",
        'version >= 1.3.34 and < 2.0 required.'
    ) unless (($x == 1 and $y == 3 and $z >= 12) or ($x == 1 and $y > 3));

    print "Found acceptable version of Apache: $x.$y.$z.\n";
    $REQ{APACHE_VERSION} = [$x,$y,$z];
    return 1;
}

sub find_apache2 {
    print "Looking for Apache with version >= 2.0.55...\n";

    # Note: be careful with the names here. The defaults have 2s in them,
    # like APACHE2_EXE, but what's put in %REQ doesn't have a 2, so APACHE_EXE.
    # It's so that later scripts like inst/conf.pl don't have to worry about
    # which version it is.

    my @paths = (split(", ", get_default("APACHE2_PATH")), path);
    my @exe = (split(", ", get_default("APACHE2_EXE")));

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
            ask_confirm(
                'Enter path to Apache 2 server binary',
                \$REQ{APACHE_EXE}
            );
        }
    } else {
        print "Failed to find Apache 2 server binary.\n";
        if (ask_yesno(
            "Do you want to provide a path to the Apache 2 server binary?",
            0,
            $QUIET,
        )) {
            $REQ{APACHE_EXE} = 'NONE';
            ask_confirm(
                "Enter path to Apache 2 server binary",
                \$REQ{APACHE_EXE}
            );
        } else {
            return soft_fail(
                "Failed to find Apache 2 executable. Looked for ",
                join(', ', @exe),
                " in:",
                map { "\n\t$_" } @paths
            );
        }
    }

    print "Found Apache executable at $REQ{APACHE_EXE}.\n";

    # check version
    my $version = `$REQ{APACHE_EXE} -v`;
    return soft_fail(
        "Failed to find Apache 2 version with `$REQ{APACHE_EXE} -v`."
    ) unless $version;
    chomp $version;
    my ($x, $y, $z) = $version =~ /(\d+)\.(\d+).(\d+)/;
    return soft_fail(
        qq{Failed to parse Apache 2 version from string "$version".}
    ) unless defined $x and defined $y and defined $z;

    return soft_fail(
        "Found unacceptable version of Apache: $x.$y.$z - ",
        "2.0.55 or greater required\n"
    ) unless ($x == 2 and ($y > 0 or ($y == 0 and $z >= 51)));

    print "Found acceptable version of Apache: $x.$y.$z.\n";
    $REQ{APACHE_VERSION} = [$x,$y,$z];

    print "Checking for preforking apache2 ... \n";
    my $compiled_modules = `$REQ{APACHE_EXE} -l`;
    return hard_fail("Bricolage and mod_perl should be run under the prefork ".
        "version of Apache2,\nrather than the threaded worker version. Please ".
        "re-compile or install\nthe preforked version. \n"
    ) unless ($compiled_modules =~ /prefork\.c/);
    print "Found prefork built in module\n";

    return 1;
}


sub find_expat {
    print "Looking for expat...\n";

    # find expat libary libexpat.so by looking in library paths that
    # Perl knows about
    my @paths = grep { defined and length } (
        split(' ', $Config{libsdirs}),
        split(' ', $Config{loclibpth}),
        split(' ', $Config{loclibpth})
    );

    push @paths, split(', ', get_default('EXPAT_PATH'));
    my @files = split(', ', get_default('EXPAT_FILE'));

    LOOK: foreach my $path (@paths) {
        foreach my $file(@files) {
            if (-e catfile($path, $file)) {
                $REQ{EXPAT} = catfile($path, "libexpat.so");
                last LOOK;
            }
        }
    }
    return soft_fail(
        "Failed to find libexpat.so. Looked in:",
        map { "\n\t$_" } @paths
    ) unless $REQ{EXPAT};
    print "Found expat at $REQ{EXPAT}.\n";

    # I should check that expat is >= 1.95.0.  Um, how do I do that?
    return 1;
}

sub get_probes {
    while (my $file = shift @ARGV) {
        $PROBES{$1}{$2} = $file if $file =~ /(db|ht)probe_(\w+)\.pl$/;
    }
}

# ask the user to choose a database or
sub get_database {
    my $dbstring = join(', ', keys(%{ $PROBES{db} }));
    print "\n\n==> Selecting Database <==\n\n";
    ask_confirm("Database ($dbstring): ", \$REQ{DB_TYPE}, $QUIET);
    print "\n\n==> Finished Selecting Database <==\n\n";
}

# ask the user to choose an apache version
sub get_httpd {
    my $htstring = join(', ', keys(%{ $PROBES{ht} }));
    print "\n\n==> Selecting Apache version <==\n\n";
    ask_confirm("httpd version ($htstring): ", \$REQ{HTTPD_VERSION}, $QUIET);
    print "\n\n==> Finished Selecting Apache version <==\n\n";
}

