#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

do_sql q{
    UPDATE grp
    SET    class__id = 43
    WHERE  class__id = 40
           AND id IN (SELECT asset_grp_id
                      FROM   workflow)
};
