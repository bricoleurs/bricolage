#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

exit if fetch_sql(qq{SELECT 1 FROM event_type WHERE key_name = 'story_aliased'});

do_sql

  q{INSERT INTO event_type (id, key_name, name, description, class__id, active)
    VALUES (NEXTVAL('seq_event_type'), 'story_aliased', 'Story Aliased', 'Story was aliased.', 10, 1)},

  q{INSERT INTO event_type_attr (id, event_type__id, name)
    VALUES (NEXTVAL('seq_event_type_attr'), CURRVAL('seq_event_type'), 'To Site')},

  q{INSERT INTO event_type (id, key_name, name, description, class__id, active)
    VALUES (NEXTVAL('seq_event_type'), 'story_alias_new', 'Story Created as Alias', 'Story was created as an alias.', 10, 1)},

  q{INSERT INTO event_type_attr (id, event_type__id, name)
    VALUES (NEXTVAL('seq_event_type_attr'), CURRVAL('seq_event_type'), 'To Site')},

  q{INSERT INTO event_type (id, key_name, name, description, class__id, active)
    VALUES (NEXTVAL('seq_event_type'), 'media_aliased', 'Media Aliased', 'Media was aliased.', 10, 1)},

  q{INSERT INTO event_type_attr (id, event_type__id, name)
    VALUES (NEXTVAL('seq_event_type_attr'), CURRVAL('seq_event_type'), 'To Site')},

  q{INSERT INTO event_type (id, key_name, name, description, class__id, active)
    VALUES (NEXTVAL('seq_event_type'), 'media_alias_new', 'Media Created as Alias', 'Media was created as an alias.', 10, 1)},

  q{INSERT INTO event_type_attr (id, event_type__id, name)
    VALUES (NEXTVAL('seq_event_type_attr'), CURRVAL('seq_event_type'), 'To Site')},
  ;

1;
__END__
