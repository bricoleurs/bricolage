#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

# We should never have used the image, audio, and video member tables.
foreach my $key (qw(image audio video)) {
    next unless test_table "$key\_member";
    do_sql
      qq{DROP TABLE $key\_member},
      qq{DROP SEQUENCE seq_$key\_member}
      ;
}

1;
__END__
