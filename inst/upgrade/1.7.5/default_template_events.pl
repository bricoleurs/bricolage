#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if fetch_sql 'SELECT 1 FROM event WHERE id = 502';

# Create creation events for all of the default templates. Set the creation
# date to the date of the first public release of Bricolage.
do_sql
  map { "INSERT INTO event (id, event_type__id, usr__id, obj_id, timestamp)
VALUES ($_, (SELECT id FROM event_type WHERE key_name = 'formatting_new'),
        0, $_, '2001-09-28 00:00')" }
  qw(502 503 504 506 507 509 510 511 512 513 514 515)
  ;
