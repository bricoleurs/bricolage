#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if fetch_sql q{SELECT 1 FROM pref WHERE id = 19};

do_sql q{
    INSERT INTO pref (id, name, description, value, def, manual, opt_type)
    VALUES ('19', 'Show Bulk Edit', 'Show button to bulk edit document elements.',
            '1', '1', '0', 'select')},

    q{INSERT INTO member (id, grp__id, class__id, active)
    VALUES ('905', '22', '48', '1')},

    q{INSERT INTO pref_member (id, object_id, member__id)
    VALUES ('19', '19', '905')},

    q{INSERT INTO pref_opt (pref__id, value, description)
    VALUES ('19', '0', 'Off')},

    q{INSERT INTO pref_opt (pref__id, value, description)
    VALUES ('19', '1', 'On')},
;


