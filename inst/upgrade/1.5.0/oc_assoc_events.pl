#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

exit if fetch_sql(qq{SELECT 1 FROM event_type WHERE key_name = 'story_add_oc'});


do_sql

  q{INSERT INTO event_type (id, key_name, name, description, class__id, active)
    VALUES (NEXTVAL('seq_event_type'), 'story_add_oc', 'Output Channel Added to Story',
                    'An output channel was associated with the story.', 10, 1)},

  q{INSERT INTO event_type_attr (id, event_type__id, name)
    VALUES (NEXTVAL('seq_event_type_attr'), CURRVAL('seq_event_type'), 'Output Channel')},

  q{INSERT INTO event_type (id, key_name, name, description, class__id, active)
    VALUES (NEXTVAL('seq_event_type'), 'story_del_oc', 'Output Channel Removed from Story',
            'An output channel was dissociated from the story.', 10, 1)},

  q{INSERT INTO event_type_attr (id, event_type__id, name)
    VALUES (NEXTVAL('seq_event_type_attr'), CURRVAL('seq_event_type'), 'Output Channel')},

  q{INSERT INTO event_type (id, key_name, name, description, class__id, active)
    VALUES (NEXTVAL('seq_event_type'), 'media_add_oc', 'Output Channel Added to Media',
                    'An output channel was associated with the media.', 46, 1)},

  q{INSERT INTO event_type_attr (id, event_type__id, name)
    VALUES (NEXTVAL('seq_event_type_attr'), CURRVAL('seq_event_type'), 'Output Channel')},

  q{INSERT INTO event_type (id, key_name, name, description, class__id, active)
    VALUES (NEXTVAL('seq_event_type'), 'media_del_oc', 'Output Channel Removed from Media',
            'An output channel was dissociated from the media.', 46, 1)},

  q{INSERT INTO event_type_attr (id, event_type__id, name)
    VALUES (NEXTVAL('seq_event_type_attr'), CURRVAL('seq_event_type'), 'Output Channel')}

  ;

