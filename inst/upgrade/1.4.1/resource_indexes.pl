#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

# check if we're already upgraded.
exit if fetch_sql(q{
    SELECT 1
    FROM   pg_class
    WHERE  relname = 'udx_resource__path__uri'
});

do_sql(q{ DROP INDEX udx_resource__path },
       q{ DROP INDEX idx_resource__uri },
       q{ CREATE UNIQUE INDEX udx_resource__path__uri ON resource(path, uri) },
       q{ CREATE INDEX idx_resource__path ON resource(path) },
       q{ CREATE INDEX idx_resource__uri ON resource(uri) },
      );
