#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

exit if fetch_sql(q{SELECT 1 FROM pref WHERE id = 16});

do_sql

  q{INSERT INTO pref (id, name, description, value, def, manual, opt_type)
    VALUES (16, 'Filter by Site Context',
           'Filter search results by the site context.',
           '0', '0', 0, 'select')},

  q{INSERT INTO member (id, grp__id, class__id, active)
    VALUES (902, 22, 48, 1)},

  q{INSERT INTO pref_member (id, object_id, member__id)
    VALUES (16, 16, 902)},

  q{INSERT INTO pref_opt (pref__id, value, description)
    VALUES (16, '0', 'Off')},

  q{INSERT INTO pref_opt (pref__id, value, description)
    VALUES (16, '1', 'On')}
  ;


1;
__END__
