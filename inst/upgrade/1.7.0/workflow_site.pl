#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

exit if test_column 'workflow', 'site__id';

do_sql
  # Add the new site__id column.
  q/ALTER TABLE workflow ADD site__id NUMERIC(10, 0)/,

  # Populate site__id with data.
  q/UPDATE workflow SET site__id = 100/,

  # Add a NOT NULL constraint.
  q{ALTER TABLE workflow
      ADD CONSTRAINT ck_workflow_null
      CHECK (site__id IS NOT NULL)},

  # Add a foreign key constraint.
  q/ALTER TABLE workflow
      ADD CONSTRAINT fk_site__workflow__site__id
      FOREIGN KEY (site__id) REFERENCES site(id)
      ON DELETE CASCADE/,

  # Drop the old name index.
  q{DROP INDEX udx_workflow__name},

  # Add the indexes.
  q{CREATE UNIQUE INDEX udx_workflow__name__site__id
    ON workflow(lower_text_num(name, site__id))},

  q{CREATE INDEX fkx_site__workflow__site__id ON workflow(site__id)},
  ;

