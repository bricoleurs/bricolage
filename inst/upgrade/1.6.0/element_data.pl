#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

exit if fetch_sql("SELECT 1 FROM event_type WHERE key_name = 'element_data_new'");

do_sql(
    qq{INSERT INTO event_type (id, key_name, name, description, class__id, active)
       VALUES (NEXTVAL('seq_event_type'), 'element_data_new',
               'Element Data Created',
               'Element Data was created.', 29, 1)},
    qq{INSERT INTO event_type_attr (id, event_type__id, name)
       VALUES (NEXTVAL('seq_event_type_attr'), CURRVAL('seq_event_type'), 'Name')},

    qq{INSERT INTO event_type (id, key_name, name, description, class__id, active)
       VALUES (NEXTVAL('seq_event_type'), 'element_data_save',
               'Element Data Saved in Element',
               'Element Data was saved in the element data profile.', 29, 1)},
    qq{INSERT INTO event_type_attr (id, event_type__id, name)
       VALUES (NEXTVAL('seq_event_type_attr'), CURRVAL('seq_event_type'), 'Name')},

    qq{INSERT INTO event_type (id, key_name, name, description, class__id, active)
       VALUES (NEXTVAL('seq_event_type'), 'element_data_del',
            'Element Data Deleted from Element',
            'Element Data was deleted from the element data profile.', 29, 1)},
    qq{INSERT INTO event_type_attr (id, event_type__id, name)
       VALUES (NEXTVAL('seq_event_type_attr'), CURRVAL('seq_event_type'), 'Name')},

    qq{UPDATE class SET disp_name   = 'Field',
                        plural_name = 'Fields',
                        description = 'Fields'
       WHERE key_name = 'element_data'},
);
