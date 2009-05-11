#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

# Exit if change already exist in db
exit if fetch_sql( qq{
    SELECT published_version, 1    
    FROM story    
} );

my @sql = (    
        "ALTER TABLE story ADD published_version numeric(10,0)",
        "ALTER TABLE media ADD published_version numeric(10,0)",
    );

do_sql( @sql );    
