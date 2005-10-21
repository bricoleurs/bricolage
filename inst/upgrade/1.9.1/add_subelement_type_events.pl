#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if fetch_sql q{SELECT 1 FROM event_type WHERE key_name = 'element_type_add'};

do_sql q{
    INSERT INTO event_type (id, key_name, name, description, class__id, active)
    VALUES (NEXTVAL('seq_event_type'), 'element_type_add', 'Element Type Subelement Added to Element Type', 'An element type subelement was added to the element type profile.', '22', '1')
},

    q{INSERT INTO event_type_attr (id, event_type__id, name)
    VALUES (NEXTVAL('seq_event_type_attr'), CURRVAL('seq_event_type'), 'Name')
},

    q{INSERT INTO event_type (id, key_name, name, description, class__id, active)
    VALUES (NEXTVAL('seq_event_type'), 'element_type_rem', 'Element Type Subelement Removed from Element Type', 'An element type subelement was removed from the element type profile.', '22', '1')
},

    q{INSERT INTO event_type_attr (id, event_type__id, name)
    VALUES (NEXTVAL('seq_event_type_attr'), CURRVAL('seq_event_type'), 'Name')
};

