#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

my $add_col = q/ALTER TABLE element ADD key_name VARCHAR(64) NOT NULL/;
my $pop_col = q/UPDATE element /.
              q/SET    key_name = TRANSLATE(LOWER(name), ' ', '_') /.
              q/WHERE  key_name IS NULL/;

# Add the new column if its not already there.  Not using 'test_sql' here since
# table alterations seem to be outside of begin() and end() transaction scope.
eval { do_sql $add_col };

# Unless the error tells us we've already added this column, die.
if ($@ and $@ !~ /"key_name" already exists/) {
    die "Error adding column 'key_name':\n\n$@\n";
}

# Populate the new key_name field
do_sql $pop_col;

__END__
