#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# If this fails, then the correct constraints are in place.
exit if test_column 'element__site', 'id';

do_sql
  # Add the new sequence.
  qq{CREATE SEQUENCE seq_element__site START 1024},

  # Add the id column.
  qq{ALTER TABLE element__site
     ADD COLUMN  id NUMERIC(10,0)},

  # Set its default to use the new sequence.
  qq{ALTER TABLE element__site
     ALTER COLUMN id SET DEFAULT NEXTVAL('seq_element__site')},

  # Make sure that it isn't null.
  qq{update element__site  set id = NEXTVAL('seq_element__site')},

  # Make sure it can never be null.
  qq{ALTER TABLE element__site
     ALTER COLUMN id SET NOT NULL},

  qq{ALTER TABLE    element__site
     ADD CONSTRAINT ck_element__site__id__null CHECK (id IS NOT NULL)},

  # Make it the primary key.
  qq{ALTER TABLE element__site
     ADD CONSTRAINT pk_element__site__id PRIMARY KEY (id)},
  ;
