#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# If this fails, then the correct constraints are in place.
exit if test_column 'event_attr', 'id';

do_sql
  # Add the new sequence.
  qq{CREATE SEQUENCE seq_event_attr START 1024},

  # Add the id column.
  qq{ALTER TABLE event_attr
     ADD COLUMN  id NUMERIC(10,0)},

  # Set its default to use the new sequence.
  qq{ALTER TABLE event_attr
     ALTER COLUMN id SET DEFAULT NEXTVAL('seq_event_attr')},

  # Make sure that it isn't null.
  qq{update event_attr  set id = NEXTVAL('seq_event_attr')},

  # Make sure it can never be null.
  qq{ALTER TABLE    event_attr
     ADD CONSTRAINT ck_event_attr__id__null CHECK (id IS NOT NULL)},

  # Make it the primary key.
  qq{ALTER TABLE event_attr ADD PRIMARY KEY (id)},
  ;
