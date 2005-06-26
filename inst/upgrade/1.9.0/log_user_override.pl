#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if fetch_sql "SELECT 1 FROM event_type WHERE key_name = 'user_overridden'";

do_sql

   "INSERT INTO event_type (id, key_name, name, description, class__id, active)
    VALUES (NEXTVAL('seq_event_type'), 'user_overridden', 'User Overridden', 'Trigger user masqueraded as user', '2', '1')"

  ;

