#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

exit if fetch_sql(qq{SELECT 1 FROM event_type WHERE key_name = 'site_new'});

do_sql

  q{INSERT INTO event_type (id, key_name, name, description, class__id, active)
    VALUES (NEXTVAL('seq_event_type'), 'site_new', 'Site Created',
            'Site was created.', 41, 1)},

  q{INSERT INTO event_type (id, key_name, name, description, class__id, active)
    VALUES (NEXTVAL('seq_event_type'), 'site_save', 'Site Saved',
            'Site profile changes were saved.', 41, 1)},

  q{INSERT INTO event_type (id, key_name, name, description, class__id, active)
    VALUES (NEXTVAL('seq_event_type'), 'site_deact', 'Site Deactivated',
            'Site was deactivated.', 41, 1)}
  ;

__END__
