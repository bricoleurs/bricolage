#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

exit if test_sql 'SELECT 1 FROM category WHERE id = 0 AND site__id = 100';

do_sql
  # Add the new site__id column.
  q/ALTER TABLE category ADD site__id NUMERIC(10, 0)/,

  # Populate it with data.
  q/UPDATE category SET site__id = 100/,

  # Add a NOT NULL constraint.
  q/ALTER TABLE category
      ADD CONSTRAINT ck_category_null
      CHECK (site__id IS NOT NULL)/,

  # Add a foreign key constraint.
  q/ALTER TABLE category ADD
    CONSTRAINT fk_category__site FOREIGN KEY (site__id)
    REFERENCES site(id) ON DELETE CASCADE/,

  # Drop the old unique index on the uri column.
  q/DROP INDEX udx_category__uri/,

  # Add a new unique index on the site and uri columns
  q/CREATE UNIQUE INDEX udx_category__site_uri ON category(site__id, uri)/,

  # Add an index on the foriegn key site id.
  q/CREATE INDEX fkx_category__site ON category(site__id)/
  ;

__END__
