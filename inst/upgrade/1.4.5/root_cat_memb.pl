#!/usr/bin/perl -w
# Add the root category to the "All Categories" Group.

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

# We're changing the value column from VARCHAR to TEXT. With TEXT, the value
# of atttypmod is -1.
exit if fetch_sql(q{SELECT 1 FROM category_member WHERE id = 1});

do_sql
  q{INSERT INTO member (id, grp__id, class__id, active)
    VALUES (58, 26, 20, 1)},

  q{INSERT INTO category_member (id, object_id, member__id)
    VALUES (1, 0, 58)}
  ;
