#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if test_table 'element__site';

do_sql

  q{CREATE TABLE element__site (
    element__id    NUMERIC(10)  NOT NULL,
    site__id       NUMERIC(10)  NOT NULL,
    active         NUMERIC(1)   DEFAULT 1
                                NOT NULL
                                CONSTRAINT ck_site_element__active CHECK (active IN (0,1)),
    primary_oc__id  NUMERIC(10,0)
)},

  q{INSERT INTO element__site (element__id, site__id, primary_oc__id) SELECT e.id, 100, primary_oc__id
    FROM element AS e, at_type AS a WHERE a.id = e.type__id AND a.top_level = 1},

  # seems broken with 7.2.3
  q{ALTER TABLE element DROP CONSTRAINT fk_output_channel__element},

  q{ALTER TABLE element RENAME COLUMN primary_oc__id TO primary_oc__id__old},

  q{DROP INDEX fkx_output_channel__element},
  ;

1;
__END__
