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

# XXX Insert ask_y_n question here.

# Okay, this database needs upgrading.
my $old_file = catfile('inst', 'upgrade.dmp');
my $new_file = catfile('inst', 'upgrade.sql');
my $sql_file = catfile('inst', 'Pg.sql');
my $tmp_file = "$sql_file.tmp";

# Dump database.
print "Dumping database. This could take a while...";
system(catfile($PG->{bin_dir}, 'pg_dump'), '-U', $PG->{root_user},
       '-O', '-x', $PG->{db_name}, '-f', $old_file, '--create');
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
mv $sql_file, $tmp_file;
mv $new_file, $sql_file;

print "\nDropping old database...";
system($PG->{psql}, '-d', 'template1', '-c', qq{DROP DATABASE "$PG->{db_name}"});
my $perl = $ENV{PERL} || $^X;
system $perl, catfile 'inst', 'db.pl';
mv $sql_file, $new_file;
mv $tmp_file, $sql_file;

__END__
  % grep -lri 'active[[:space:]]*=[[:space:]]*[01]' lib \
    | grep -v .svn | xargs \
    perl -i.bak -pe "s/active\s*=\s*([01])/active = '\$1'/ig"
