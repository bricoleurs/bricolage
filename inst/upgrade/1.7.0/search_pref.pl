#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

exit if fetch_sql(q{SELECT 1 FROM pref WHERE id = 12});

do_sql

  q{INSERT INTO pref (id, name, description, value, def, manual, opt_type)
    VALUES (12, 'Default Search',
            'Whether Find Media and Find Stories use Simple or Advanced Search by default.',
            '0', '0', 0, 'select')},

  q{INSERT INTO member (id, grp__id, class__id, active)
    VALUES (169, 22, 48, 1)},

  q{INSERT INTO pref_member (id, object_id, member__id)
    VALUES (12, 12, 169)},

  q{INSERT INTO pref_opt (pref__id, value, description)
    VALUES (12, '0', 'Simple')},

  q{INSERT INTO pref_opt (pref__id, value, description)
    VALUES (12, '1', 'Advanced')},

  ;


1;
__END__
