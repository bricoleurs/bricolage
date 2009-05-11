#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

# Exit if change already exist in db
exit if fetch_sql( qq{
    SELECT     1
    FROM     pref
    WHERE    name = 'URI Case'
} );

my @sql = (
    "INSERT INTO pref (id, name, description, value, def, manual)
        VALUES ('9', 'URI Case', 'Controls the case of the characters that make up URIs',
        'mixed', 'mixed', 0)",
    "INSERT INTO member (id, grp__id, class__id, active) VALUES (166, 22, 48, 1)",
    "INSERT INTO pref_member (id, object_id, member__id) VALUES (9, 9, 166)", 
    "INSERT INTO pref_opt (pref__id, value, description)
        VALUES (9, 'lower', 'Lowercase Characters [a-z]')",
    "INSERT INTO pref_opt (pref__id, value, description)
        VALUES (9, 'upper', 'Uppercase Characters [A-Z]')",
    "INSERT INTO pref_opt (pref__id, value, description)
        VALUES (9, 'mixed', 'URI tokens unaltered')",
    );

do_sql( @sql );    
