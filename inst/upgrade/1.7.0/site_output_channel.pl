#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

exit if test_sql 'SELECT 1 FROM output_channel WHERE id = 1 AND site__id = 100';

do_sql
  # Add the new site__id column.
  q/ALTER TABLE output_channel ADD site__id NUMERIC(10, 0)/,

  # Add the new protocol column.
  q/ALTER TABLE output_channel ADD protocol VARCHAR(16)/,

  # Populate site__id with data.
  q/UPDATE output_channel SET site__id = 100/,

  # Add a NOT NULL constraint.
  q{ALTER TABLE output_channel
      ADD CONSTRAINT ck_output_channel_null
      CHECK (site__id IS NOT NULL)},

  # Add a foreign key constraint.
  q/ALTER TABLE output_channel
      ADD CONSTRAINT fk_output_channel__site
      FOREIGN KEY (site__id) REFERENCES site(id)
      ON DELETE CASCADE/,

  # Add an index.
  q/CREATE INDEX fkx_output_channel__site ON output_channel(site__id)/,

  # Drop the old index on the name column.
  qq{DROP INDEX udx_output_channel__name},

  # Add a new aggregate index.
  q/CREATE UNIQUE INDEX udx_output_channel__site
      ON output_channel(name, site__id)/
;

__END__
