#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

exit if test_sql "SELECT 1 WHERE EXISTS (SELECT id FROM image_member)";

# We should never have used the image, audio, and video member tables.
foreach my $key (qw(image audio video)) {
    do_sql
      qq{DROP TABLE $key\_member},
      qq{DROP SEQUENCE seq_$key\_member}
      ;
}

1;
__END__
