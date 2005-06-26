#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if fetch_sql "SELECT 1 FROM event_type WHERE key_name = 'media_del_file'";

do_sql

   "INSERT INTO event_type (id, key_name, name, description, class__id, active)
    VALUES (NEXTVAL('seq_event_type'), 'media_del_file', 'Media File Removed from Media', 'The media file was dissociated from the media.', '46', '1')"

  ;

