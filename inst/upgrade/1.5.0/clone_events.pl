#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

exit if fetch_sql(qq{SELECT 1 FROM event_type WHERE key_name = 'story_clone'});

do_sql
  q{INSERT INTO event_type (id, key_name, name, description, class__id, active)
    VALUES (NEXTVAL('seq_event_type'), 'story_clone', 'Story Cloned',
            'Story was cloned.', 10, 1)},

  q{INSERT INTO event_type (id, key_name, name, description, class__id, active)
    VALUES (NEXTVAL('seq_event_type'), 'story_clone_create',
            'Story Created as Clone', 'Story was created by cloning.', 10, 1)}
  ;
