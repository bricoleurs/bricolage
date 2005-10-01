#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit unless test_column 'field_type', 'map_type__id';

do_sql
    q{ ALTER TABLE field_type
       DROP  COLUMN map_type__id
    },
;

1;
__END__
