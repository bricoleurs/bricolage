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
  q/CREATE INDEX fkx_category__site ON category(site__id)/,

  #==================================================#
  # Add the new default category

  # Change the URI for the old default, now master, category
  q/UPDATE category SET uri = '' WHERE id = 0/,

  # The category entry
  q!INSERT INTO category (id,site__id,directory, uri, parent_id,
                          name, description, asset_grp_id)
    VALUES (1, 100,'', '/', 0,
            'Default Root Category', 'Default Root Category', 68)!,

  # Put it into the All Categories group.
  q/INSERT INTO member (id, grp__id, class__id, active)
    VALUES (61, 26, 20, 1)/,

  # Add the member for the all categories group
  q/INSERT INTO category_member (id, object_id, member__id)
    VALUES (2, 1, 61)/,

  # Update the existing categories to the new root category
  q/UPDATE category SET parent_id = 1 WHERE parent_id = 0 AND id not in (0,1)/,

  # Update all objects that have foriegn keys to category
  q/UPDATE media_instance  SET category__id = 1 WHERE category__id = 0/,
  q/UPDATE story__category SET category__id = 1 WHERE category__id = 0/,
  q/UPDATE formatting      SET category__id = 1 WHERE category__id = 0/,
  ;

__END__
