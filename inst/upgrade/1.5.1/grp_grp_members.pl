#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

# Exit if change already exists in db
exit if fetch_sql(qq{
   SELECT  1
   FROM    member
   WHERE   id = 630
});


do_sql

  q{INSERT INTO member (id, grp__id, class__id, active)
    VALUES (630, 35, 6, 1)},

  q{INSERT INTO grp_member (id, object_id, member__id)
    VALUES (630, 330, 630)},

  q{INSERT INTO member (id, grp__id, class__id, active)
    VALUES (631, 35, 6, 1)},

  q{INSERT INTO grp_member (id, object_id, member__id)
    VALUES (631, 331, 631)},

  q{INSERT INTO member (id, grp__id, class__id, active)
    VALUES (632, 35, 6, 1)},

  q{INSERT INTO grp_member (id, object_id, member__id)
    VALUES (632, 332, 632)},

  q{INSERT INTO member (id, grp__id, class__id, active)
    VALUES (633, 35, 6, 1)},

  q{INSERT INTO grp_member (id, object_id, member__id)
    VALUES (633, 333, 633)},

  q{INSERT INTO member (id, grp__id, class__id, active)
    VALUES (634, 35, 6, 1)},

  q{INSERT INTO grp_member (id, object_id, member__id)
    VALUES (634, 334, 634)},

  q{INSERT INTO member (id, grp__id, class__id, active)
    VALUES (635, 35, 6, 1)},

  q{INSERT INTO grp_member (id, object_id, member__id)
    VALUES (635, 335, 635)},

  q{INSERT INTO member (id, grp__id, class__id, active)
    VALUES (640, 35, 6, 1)},

  q{INSERT INTO grp_member (id, object_id, member__id)
    VALUES (640, 340, 640)},

  q{INSERT INTO member (id, grp__id, class__id, active)
    VALUES (641, 35, 6, 1)},

  q{INSERT INTO grp_member (id, object_id, member__id)
    VALUES (641, 341, 641)},

  q{INSERT INTO member (id, grp__id, class__id, active)
    VALUES (164, 35, 6, 1)},

  q{INSERT INTO grp_member (id, object_id, member__id)
    VALUES (49, 68, 164)},

  q{INSERT INTO member (id, grp__id, class__id, active)
    VALUES (501, 35, 6, 1)},

  q{INSERT INTO grp_member (id, object_id, member__id)
    VALUES (50, 41, 501)},

  q{INSERT INTO member (id, grp__id, class__id, active)
    VALUES (502, 35, 6, 1)},

  q{INSERT INTO grp_member (id, object_id, member__id)
    VALUES (51, 42, 502)},

  q{INSERT INTO member (id, grp__id, class__id, active)
    VALUES (503, 35, 6, 1)},

  q{INSERT INTO grp_member (id, object_id, member__id)
    VALUES (52, 43, 503)},

  q{INSERT INTO member (id, grp__id, class__id, active)
    VALUES (504, 35, 6, 1)},

  q{INSERT INTO grp_member (id, object_id, member__id)
    VALUES (53, 44, 504)},

  q{INSERT INTO member (id, grp__id, class__id, active)
    VALUES (505, 35, 6, 1)},

  q{INSERT INTO grp_member (id, object_id, member__id)
    VALUES (54, 45, 505)},

  q{INSERT INTO member (id, grp__id, class__id, active)
    VALUES (506, 35, 6, 1)},

  q{INSERT INTO grp_member (id, object_id, member__id)
    VALUES (55, 46, 506)},

  ;

