#!/usr/bin/perl -w
# Add media_type to table 'class'.
# Add media_type event types to table 'event_type'.
# Correct typos in lib/Bric/Util/Class.val and EventType.val.

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

# Exit if change already exists in db
exit if fetch_sql( qq{
       SELECT  1
       FROM    class
       WHERE   key_name = 'media_type'
} );

my @sql = (
    # Add media_type to 'class'
    "INSERT INTO class (id, key_name, pkg_name, disp_name, plural_name, description, distributor)
     VALUES (72, 'media_type', 'Bric::Util::MediaType', 'Media Type', 'Media Types',
     'Media Type objects', 0)",

    # Add media_type event types to 'event_type'
    "INSERT INTO event_type (id, key_name, name, description, class__id, active)
     VALUES (NEXTVAL('seq_event_type'), 'media_type_new', 'Media Type Created',
     'Media Type was created.', 72, 1)",
    "INSERT INTO event_type (id, key_name, name, description, class__id, active)
     VALUES (NEXTVAL('seq_event_type'), 'media_type_save', 'Media Type Saved',
     'Media Type profile changes were saved.', 72, 1)",
    "INSERT INTO event_type (id, key_name, name, description, class__id, active)
     VALUES (NEXTVAL('seq_event_type'), 'media_type_deact', 'Media Type Deactivated',
     'Media Type profile was deactivated.', 72, 1)",

    # Spelling corrections
    "UPDATE class SET description = 'Contributor Type objects'
     WHERE key_name = 'contrib_type'",
    "UPDATE class SET description = 'Group of destinations'
     WHERE key_name = 'dest_grp'",
    "UPDATE event_type SET description = 'Template check out was canceled.'
     WHERE key_name = 'formatting_cancel_checkout'",
);

do_sql( @sql );
