#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# Make sure that we haven't run this update before.
exit if fetch_sql qq{
  SELECT 1
  WHERE EXISTS (
          SELECT 1
          FROM   grp, category
          WHERE  category.asset_grp_id = grp.id
                 AND grp.name LIKE 'Site%'
        )
};

# Update the category asset group names by adding the Site ID to them.
do_sql qq{
  UPDATE grp
  SET    name = 'Site ' || category.site__id || ' Category Assets'
  FROM   category
  WHERE  grp.name = 'Category Assets'
         AND category.asset_grp_id = grp.id
};
