#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# If this fails, then the correct constraints are in place.
exit if test_column 'media_uri', 'id';

do_sql
  # Add the new sequence.
  qq{CREATE SEQUENCE seq_media_uri START 1024},

  # Add the id column.
  qq{ALTER TABLE media_uri
     ADD COLUMN  id NUMERIC(10,0)},

  # Set its default to use the new sequence.
  qq{ALTER TABLE media_uri
     ALTER COLUMN id SET DEFAULT NEXTVAL('seq_media_uri')},

  # Make sure that it isn't null.
  qq{update media_uri  set id = NEXTVAL('seq_media_uri')},

  # Make sure it can never be null.
  qq{ALTER TABLE    media_uri
     ADD CONSTRAINT ck_media_uri__id__null CHECK (id IS NOT NULL)},

  # Make it the primary key.
  qq{ALTER TABLE media_uri ADD PRIMARY KEY (id)},
  ;
