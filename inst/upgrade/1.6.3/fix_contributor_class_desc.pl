#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

exit if fetch_sql "SELECT 1 FROM class where description = 'Contributor Type objects'";

do_sql
  q{UPDATE class
    SET    description = 'Contributor Type objects'
    WHERE  key_name = 'contrib_type'},
  ;

1;
__END__
