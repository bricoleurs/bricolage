#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if fetch_sql("SELECT 1 FROM action_type__media_type WHERE action_type__id = 1");

do_sql
   # Insert missing media type assocations.
  qq{INSERT INTO action_type__media_type (action_type__id, media_type__id)
     VALUES (1, 0)},
  qq{INSERT INTO action_type__media_type (action_type__id, media_type__id)
     VALUES (5, (SELECT id FROM media_type WHERE name = 'text/html'))},
  qq{INSERT INTO action_type__media_type (action_type__id, media_type__id)
     VALUES (5, (SELECT id FROM media_type WHERE name = 'text/xml'))},
  qq{INSERT INTO action_type__media_type (action_type__id, media_type__id)
     VALUES (5, (SELECT id FROM media_type WHERE name = 'application/xhtml+xml'))},
  qq{INSERT INTO action_type__media_type (action_type__id, media_type__id)
     VALUES (4, 0)},
  ;

1;
