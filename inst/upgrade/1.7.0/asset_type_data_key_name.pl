#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

my $rename_col = q/ALTER TABLE at_data RENAME name TO key_name/;
my $update_col = q/UPDATE at_data /.
                 q/SET    key_name = TRANSLATE(LOWER(key_name), ' ', '_')/;

# Rename the new column if its not already been done.  Not using 'test_sql'
# here since table alterations seem to be outside of begin() and end()
# transaction scope.
eval { do_sql $rename_col };

# Unless the error tells us we've already renamed this column, die.
if ($@ and $@ !~ /"name" does not exist/) {
    die "Error adding column 'key_name':\n\n$@\n";
}

# Update the existing key_name data
do_sql $update_col;

__END__
