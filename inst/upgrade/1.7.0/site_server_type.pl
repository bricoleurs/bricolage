#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

exit if test_sql 'SELECT 1 FROM server_type WHERE id = 1 AND site__id = 100';

do_sql
  # Add the new site__id column.
  q/ALTER TABLE server_type ADD site__id NUMERIC(10, 0)/,

  # Populate site__id with data.
  q/UPDATE server_type SET site__id = 100/,

  # Add a NOT NULL constraint.
  q{ALTER TABLE server_type
      ADD CONSTRAINT ck_server_type_site_null
      CHECK (site__id IS NOT NULL)},

  # Add a foreign key constraint.
  q/ALTER TABLE server_type
      ADD CONSTRAINT fk_site__server_type
      FOREIGN KEY (site__id) REFERENCES site(id)
      ON DELETE CASCADE/,

  # Add an index.
  q/CREATE INDEX fkx_site__server_type ON server_type(site__id)/,

  # Drop the old index on the name column.
  qq{DROP INDEX udx_server_type__name},

  # Add a new aggregate index.
  q/CREATE UNIQUE INDEX udx_server_type__name_site
      ON server_type(name, site__id)/
;

__END__
