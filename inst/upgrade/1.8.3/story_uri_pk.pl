#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# If this fails, then the correct constraints are in place.
exit if test_column 'story_uri', 'id';

do_sql
  # Add the new sequence.
  qq{CREATE SEQUENCE seq_story_uri START 1024},

  # Add the id column.
  qq{ALTER TABLE story_uri
     ADD COLUMN  id NUMERIC(10,0)},

  # Set its default to use the new sequence.
  qq{ALTER TABLE story_uri
     ALTER COLUMN id SET DEFAULT NEXTVAL('seq_story_uri')},

  # Make sure that it isn't null.
  qq{update story_uri  set id = NEXTVAL('seq_story_uri')},

  # Make sure it can never be null.
  qq{ALTER TABLE story_uri
     ALTER COLUMN id SET NOT NULL},

  qq{ALTER TABLE    story_uri
     ADD CONSTRAINT ck_story_uri__id__null CHECK (id IS NOT NULL)},

  # Make it the primary key.
  qq{ALTER TABLE story_uri ADD PRIMARY KEY (id)},
  ;
