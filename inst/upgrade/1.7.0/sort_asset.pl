#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

exit if fetch_sql(q{SELECT 1 FROM pref WHERE id = 13});

do_sql

  q{INSERT INTO pref (id, name, description, value, def, manual, opt_type)
    VALUES (13, 'Default Asset Sort',
            'The default Story/Media field to sort on.',
            'cover_date', 'cover_date', 0, 'select')},

  q{INSERT INTO member (id, grp__id, class__id, active)
    VALUES (170, 22, 48, 1)},

  q{INSERT INTO pref_member (id, object_id, member__id)
    VALUES (13, 13, 170)},

  q{INSERT INTO pref_opt (pref__id, value, description)
    VALUES (13, 'cover_date', 'Cover Date')},

  q{INSERT INTO pref_opt (pref__id, value, description)
    VALUES (13, 'priority', 'Priority')},

  q{INSERT INTO pref_opt (pref__id, value, description)
    VALUES (13, 'name', 'Title')},

  q{INSERT INTO pref_opt (pref__id, value, description)
    VALUES (13, 'category_name', 'Category')},

  q{INSERT INTO pref_opt (pref__id, value, description)
    VALUES (13, 'site_id', 'Site')},

  q{INSERT INTO pref_opt (pref__id, value, description)
    VALUES (13, 'element', 'Media Type')},

  q{INSERT INTO pref_opt (pref__id, value, description)
    VALUES (13, 'id', 'ID')}

  ;


1;
__END__
