#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

# Exit if change already exist in db
exit if fetch_sql( qq{
       SELECT  1
       FROM    pref
       WHERE   name = 'Search Results / Page'
} );

my @sql = (
       "INSERT INTO pref (id, name, description, value, def, manual) 
               VALUES ('10', 'Search Results / Page', 
                       'Controls the number of records displayed per page from searches', 
                        0, 0, '0')",
       "INSERT INTO member (id, grp__id, class__id, active) 
               VALUES (167, 22, 48, 1)",
       "INSERT INTO pref_member (id, object_id, member__id) 
               VALUES (10, 10, 167)",
       "INSERT INTO pref_opt (pref__id, value, description)
               VALUES (10, '0', 'Off')",
       "INSERT INTO pref_opt (pref__id, value, description)
               VALUES (10, '10', '10')",
       "INSERT INTO pref_opt (pref__id, value, description)
               VALUES (10, '20', '20')",
       "INSERT INTO pref_opt (pref__id, value, description)
               VALUES (10, '30', '30')",
       "INSERT INTO pref_opt (pref__id, value, description)
               VALUES (10, '40', '40')",
       "INSERT INTO pref_opt (pref__id, value, description)
               VALUES (10, '50', '50')"
       );

do_sql( @sql );
