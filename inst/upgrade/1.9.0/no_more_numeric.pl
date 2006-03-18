#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catfile);
use File::Copy qw(mv);

our $PG;
do "./postgres.db" or die "Failed to read postgres.db: $!";

$ENV{PGUSER} = $PG->{root_user};
$ENV{PGPASSWORD} = $PG->{root_pass};
$ENV{PGHOST} = $PG->{host_name} if $PG->{host_name};
$ENV{PGPORT} = $PG->{host_port} if $PG->{host_port};

# See if we get a boolean value instead of a number.
my (undef, $val) = `$PG->{psql} -q -c 'select active from person LIMIT 1;' -d '$PG->{db_name}' -P format=unaligned -P pager= -P footer=`;
chomp $val;
exit if $val eq 't' || $val eq 'f';

# Find out if they *really* want to do this.
exit unless y_n(
qq{

    ####################################################################
    ####################################################################

    As of version 1.9.0, Bricolage has switched to much more efficient
    data types in the database. However, in order to upgrade existing
    installations to take advantage of the new data types, the database
    must be dumped to a temporary file, its contents parsed for the
    old data types, and converted to the new data types.

    This upgrade script will handle this process for you. It will dump
    the database, convert it to the new data types, delete the old
    database, and create a new database with the converted dump file.
    We *strongly* recommend that you back up the database before
    allowing the upgrade to proceed. Also, there *must* be enough space
    in this directory for two copies of the dumped database.

    However, this conversion is not required to continue using
    Bricolage. The code is written in such a way that it should continue
    to work with the old data types in the database. You can therefore
    decline this upgrade if you wish. That said, only the new data types
    will be supported going forward (though we will make every effort
    to ensure that databases with the older data types continue to
    work for the lifetime of Bricolage 1.x). And the new datatypes have
    the potential to increase the performance of Bricolage. We therefore
    STRONGLY recommend that you take advantage of them by accepting this
    upgrade.

    Would you like to the database data types to be upgraded now?},
  'y');

# Okay, this database needs upgrading.
print "\n\n";
my $old_file = catfile('inst', 'db_tmp', 'upgrade.dmp');
my $new_file = catfile('inst', 'db_tmp', 'upgrade.sql');
my $sql_file = catfile('inst', 'Pg.sql');
my $tmp_file = "$sql_file.tmp";

# Dump database.
print "Dumping database. This could take a while...";
system(catfile($PG->{bin_dir}, 'pg_dump'), '-U', $PG->{root_user},
       '-O', '-x', '-f', $old_file, $PG->{db_name});
print "\nParsing datbase...";
open OLD, "<$old_file" or die "Cannot open '$old_file: $!\n";
open NEW, ">$new_file" or die "Cannot open '$new_file: $!\n";
my $last = '';
while (<OLD>) {
    # Stop this craziness once we get to the data section.
    last if /^-- Data/;
    # Skip the old boolean checks.
    next if /CHECK\s*\(\(\(\w+\s*=\s*\([01]\)::numeric\)\s*OR\s*\(\w+\s*=\s*\([01]\)::numeric\)\)\)/;
    # Handle functions and such.
    unless (s/numeric([),])/integer$1/g) {
        # Handle special smallint columns.
        unless (s/(uri_case|tplate_type|ord|priority|place|burner|uri_case|tries|"type")\s+numeric\([123],0\)/$1 smallint/) {
            # Handle old standard numeric(10,0) columns.
            unless (s/numeric\(10,0\)/integer/) {
                # Handle other smallints.
                unless (s/numeric\([234],0\)/smallint/) {
                    # A numeric(1,0) is either boolean or smallint. Decide
                    # based on the default.
                    if (/^\s+"?\w+"?\s+numeric\(1,\s*0\)/i) {
                        if (/default\s+[2-9]/i) {
                            s/^(\s+"?\w+"?)\s+numeric\(1,\s*0\)/$1 smallint/i;
                        } else {
                            s/^(\s+"?\w+"?)\s+numeric\(1,\s*0\)/$1 boolean/i;
                            s/DEFAULT\s+0/DEFAULT false/i
                              unless s/DEFAULT\s+1/DEFAULT true/i;
                        }
                    } else {
                        # Just replace any remaining NUMERIC casts with integer casts.
                        s/::numeric/::integer/g
                          unless s/^(\s+"?\w+"?)\s+numeric\(\d+,\s*0\)/$1 integer/i;
                    }
                }
            }
        }
        # Remove commas from the last line of of a statement.
        $last =~ s/,$// if $_ =~ /^\);/;
    }

    # Fix incompatible checks.
    if (/ck_(?:story|media)__publish_status/) {
        s/\(0\)::integer/FALSE/g;
        s/\(1\)::integer/TRUE/g;
    }

    # Print the previouis line.
    print NEW $last;
    $last = $_;
}

# Print the current line.
print NEW $last, $_;
# Fix the casts in the rest of the file.
while (<OLD>) {
    s/::numeric/::integer/g
      unless s/active\s*=\s*\(1\)::numeric/active = ('t')::bool/;
    print NEW $_;
}

close OLD;
close NEW;
unlink $old_file;

# Move things around so that db.pl can see them.
#mv $sql_file, $tmp_file;
#mv $new_file, $sql_file;

print "\nDropping old database...";
$ENV{PGSQL} = $new_file;
system($PG->{psql}, '-U', $PG->{root_user}, '-d', 'template1',
       '-c', qq{DROP DATABASE "$PG->{db_name}"}) and die;
my $perl = $ENV{PERL} || $^X;
system $perl, catfile 'inst', 'db.pl';

# Restore the file locations.
#mv $sql_file, $new_file;
#mv $tmp_file, $sql_file;

##############################################################################
# This stuff is copied from bric_upgrade.pm so we don't load that module and
# therefore connect to the database.

sub prompt {
    die "prompt() called without a prompt message" unless @_;
    my ($msg, $def) = @_;

    ($def, my $dispdef) = defined $def ? ($def, "[$def] ") : ('', ' ');

    do {
        local $|=1;
        print "$msg $dispdef";
    };

    my $ans;
    if (-t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT))) {
        $ans = <STDIN>;
        if (defined $ans) {
            chomp $ans;
        } else { # user hit ctrl-D
            print $/;
        }
    }

    return defined $ans && length $ans ? $ans : $def;
}

sub y_n {
    die "y_n() called without a prompt message" unless @_;

    while (1) {
        my $ans = prompt(@_);
        return 1 if $ans =~ /^y/i;
        return 0 if $ans =~ /^n/i;
        print "Please answer 'y' or 'n'.\n";
    }
}

__END__
  % grep -lri 'active[[:space:]]*=[[:space:]]*[01]' lib \
    | grep -v .svn | xargs \
    perl -i.bak -pe "s/active\s*=\s*([01])/active = '\$1'/ig"
