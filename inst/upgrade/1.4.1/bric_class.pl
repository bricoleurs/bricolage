#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

# check if we're already upgraded.
exit if (fetch_sql(q{ SELECT * FROM class WHERE id = 0 AND description <> '0' }));

do_sql(qq{ UPDATE class
           SET    key_name = 'bric',
                  pkg_name = 'Bric',
                  plural_name = 'Bricolagen',
                  disp_name   = 'Bricolage',
                  description = 'Bricolage Root Class',
                  distributor = 0
           WHERE  id = 0

})
