#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

exit if fetch_sql(qq{
    SELECT 1
    FROM   class
    WHERE  id = 74
});

do_sql(qq{
    INSERT INTO class (id, key_name, pkg_name, disp_name, plural_name,
                       description, distributor)
    VALUES (74, 'webdav', 'Bric::Util::Trans::WebDav', 'WebDAV', 'WebDav Transport',
            'Class with methods to move files via WebDav', 1)
});
