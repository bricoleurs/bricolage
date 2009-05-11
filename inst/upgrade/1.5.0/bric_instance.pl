#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

# Exit if change already exist in db
exit if fetch_sql( qq{
       SELECT  1
       FROM    pref
       WHERE   name = 'Bricolage Instance Name'
} );

my @sql = (
       # Add 'opt_type' column
       "ALTER TABLE pref ADD COLUMN opt_type VARCHAR(16)",
       "UPDATE pref SET opt_type = 'select' WHERE id <> 6",
       "UPDATE pref SET opt_type = 'radio' WHERE id = 6",
       "ALTER TABLE pref ADD CONSTRAINT chk_opt_type_null CHECK (opt_type IS NOT NULL)",

       # Initialize 'Bricolage Instance Name' Preference
       "INSERT INTO pref (id, name, description, value, def, manual, opt_type)
            VALUES ('11', 'Bricolage Instance Name',
            'Label used in window titles and the Welcome to Bricolage message on the login page.',
            'Bricolage', 'Bricolage', 1, 'text')",
       "INSERT INTO member (id, grp__id, class__id, active)
            VALUES (168, 22, 48, 1)",
       "INSERT INTO pref_member (id, object_id, member__id)
            VALUES (11, 11, 168)",
       "INSERT INTO pref_opt (pref__id, value, description)
            VALUES (11, 'Bricolage', 'Bricolage')",
);

do_sql( @sql );
