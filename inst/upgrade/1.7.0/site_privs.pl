#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

exit if fetch_sql(qq{SELECT 1 FROM grp_priv WHERE id = 47});

do_sql
  q{INSERT INTO grp_priv (id, grp__id, value)
    VALUES(47, 21, 3)},

  q{INSERT INTO grp_priv__grp_member (grp_priv__id, grp__id)
    VALUES(47, 47)}
  ;

1;
__END__
