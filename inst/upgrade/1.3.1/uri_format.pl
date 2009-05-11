#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

# Exit if change already exist in db
exit if fetch_sql( qq{
    SELECT     1
    FROM     pref
    WHERE    name = 'URI Format'
} );

my @sql = (
    "ALTER TABLE pref ADD COLUMN manual NUMERIC(1,0)",
    "ALTER TABLE pref ADD CONSTRAINT ck_manual__pref CHECK(manual IN(0,1))",
    "UPDATE pref SET manual = 0",
    "INSERT INTO pref (id, name, description, value, def, manual)
        VALUES ('7', 'URI Format', 'Controls format of assets URIs',
        '/categories/year/month/day/slug/', '/categories/year/month/day/slug/', 1)",
    "INSERT INTO member (id, grp__id, class__id, active) VALUES (164, 22, 48, 1)",
    "INSERT INTO pref_member (id, object_id, member__id) VALUES (7, 7, 164)",
    "INSERT INTO pref_opt (pref__id, value, description)
        VALUES (7, '/categories/year/month/day/slug/', '/categories/year/month/day/slug/')",
    "INSERT INTO pref (id, name, description, value, def, manual)
        VALUES ('8', 'Fixed URI Format', 'Controls URI format for assets with fixed URIs', '/categories/', '/categories/', 1)",
    "INSERT INTO member (id, grp__id, class__id, active) VALUES (165, 22, 48, 1)",
    "INSERT INTO pref_member (id, object_id, member__id) VALUES (8, 8, 165)", 
    "INSERT INTO pref_opt (pref__id, value, description) VALUES (8, '/categories/', '/categories/')" );

do_sql( @sql );
