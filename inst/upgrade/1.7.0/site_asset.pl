#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

exit if test_sql "SELECT 1 WHERE EXISTS (SELECT site__id FROM formatting)";

do_sql
  #formatting
  # Add the new site__id column.
  q/ALTER TABLE formatting ADD site__id NUMERIC(10, 0)/,

  # Populate site__id with data.
  q/UPDATE formatting SET site__id = 100/,


  # Add a NOT NULL constraint.
  q{ALTER TABLE formatting
      ADD CONSTRAINT ck_formatting_null
      CHECK (site__id IS NOT NULL)},

  # Add a foreign key constraint.
  q/ALTER TABLE formatting
      ADD CONSTRAINT fk_site__formatting
      FOREIGN KEY (site__id) REFERENCES site(id)
      ON DELETE RESTRICT/,

  # Add the index.
  q/CREATE INDEX fkx_site__formatting ON formatting(site__id)/,

  #media
  # Add the new site__id column.
  q/ALTER TABLE media ADD site__id NUMERIC(10, 0)/,

  # Populate site__id with data.
  q/UPDATE media SET site__id = 100/,

  # Add a NOT NULL constraint.
  q{ALTER TABLE media
      ADD CONSTRAINT ck_media_null
      CHECK (site__id IS NOT NULL)},

  # Add a foreign key constraint.
  q/ALTER TABLE media
      ADD CONSTRAINT fk_site__media
      FOREIGN KEY (site__id) REFERENCES site(id)
      ON DELETE RESTRICT/,

  # Add the index.
  q/CREATE INDEX fkx_site__media ON media(site__id)/,


  q/ALTER TABLE media
      ADD alias_id NUMERIC (10,0)
      CONSTRAINT ck_media_id
      CHECK (alias_id != id)/,

  q/ALTER TABLE media
      ADD CONSTRAINT fk_media__media_id FOREIGN KEY (alias_id)
      REFERENCES media(id) ON DELETE RESTRICT/,

  q/CREATE INDEX fdx_alias_id__media ON media(alias_id)/,

  #story
  # Add the new site__id column.
  q/ALTER TABLE story ADD site__id NUMERIC(10, 0)/,

  # Populate site__id with data.
  q/UPDATE story SET site__id = 100/,

  # Add a NOT NULL constraint.
  q{ALTER TABLE story
      ADD CONSTRAINT ck_story_null
      CHECK (site__id IS NOT NULL)},

  # Add a foreign key constraint.
  q/ALTER TABLE story
      ADD CONSTRAINT fk_site__story
      FOREIGN KEY (site__id) REFERENCES site(id)
      ON DELETE RESTRICT/,

  # Add the index.
  q/CREATE INDEX fkx_site__story ON story(site__id)/,

  q/ALTER TABLE story
      ADD alias_id NUMERIC (10,0)
      CONSTRAINT ck_story_id
      CHECK (alias_id != id)/,

  q/ALTER TABLE story
      ADD CONSTRAINT fk_story__story_id FOREIGN KEY (alias_id)
      REFERENCES story(id) ON DELETE RESTRICT/,

  q/CREATE INDEX fdx_alias_id__story ON story(alias_id)/,

;

