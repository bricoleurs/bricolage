#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

exit if fetch_sql(qq{SELECT 1 FROM event_type WHERE key_name = 'keyword_new'});

do_sql

  q{INSERT INTO event_type (id, key_name, name, description, class__id, active)
    VALUES (NEXTVAL('seq_event_type'), 'keyword_new', 'Keyword Created',
            'Keyword was created.', 41, 1)},

  q{INSERT INTO event_type (id, key_name, name, description, class__id, active)
    VALUES (NEXTVAL('seq_event_type'), 'keyword_save', 'Keyword Saved',
            'Keyword profile changes were saved.', 41, 1)},

  q{INSERT INTO event_type (id, key_name, name, description, class__id, active)
    VALUES (NEXTVAL('seq_event_type'), 'keyword_deact', 'Keyword Deactivated',
            'Keyword was deactivated.', 41, 1)}
  ;

