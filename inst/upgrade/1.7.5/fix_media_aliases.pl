#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

do_sql
  "UPDATE media_instance
   SET    file_name = ''
   WHERE  media__id IN (
            SELECT id FROM media WHERE alias_id IS NOT NULL
          )
  ";
