#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

my $add_col = q/ALTER TABLE category ADD site__id NUMERIC(10,0) NOT NULL/;
my $add_ref = q/ALTER TABLE category ADD
                CONSTRAINT fk_site__category FOREIGN KEY (site__id)
                REFERENCES site(id) ON DELETE CASCADE/;
my $pop_col = q/UPDATE category /.
              q/SET    site__id = 100 /.
              q/WHERE  site__id IS NULL/;

# Add the new column if its not already there.  Not using 'test_sql' here since
# table alterations seem to be outside of begin() and end() transaction scope.
eval { do_sql $add_col };

# If we have an error, die if its anything but 'Error adding...'
if ($@) {
    unless ($@ =~ /"site__id" already exists/) {
        die "\n\nError adding column 'site__id':\n\n$@\n";
    }
}
# No error, the column was just added, apply foreign key constraints
else {
    do_sql $add_ref;
}

# Populate the new site__id field
do_sql $pop_col;

__END__
