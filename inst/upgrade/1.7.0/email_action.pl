#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

exit if fetch_sql("SELECT 1 FROM action_type WHERE id = 4");

do_sql
  q{INSERT INTO action_type ( id, name, description, active)
    VALUES (4, 'Email', 'Email resources.', 1)},

  q{INSERT INTO action_type__media_type (action_type__id, media_type__id)
    VALUES (4, 0)}
  ;

1;
