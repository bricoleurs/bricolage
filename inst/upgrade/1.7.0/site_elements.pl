#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

exit if test_sql(qq{SELECT 1 FROM element__site});

do_sql

q{CREATE TABLE element__site (
    element__id    NUMERIC(10)  NOT NULL,
    site__id       NUMERIC(10)  NOT NULL,
    active         NUMERIC(1)   DEFAULT 1
                                NOT NULL
                                CONSTRAINT ck_site_element__active CHECK (active IN (0,1)),
    primary_oc__id  NUMERIC(10,0)
)},

q{CREATE UNIQUE INDEX udx_element__site on element__site(element__id, site__id)},

q{ALTER TABLE element__site ADD
    CONSTRAINT fk_site__element__site__site__id FOREIGN KEY (site__id)
    REFERENCES site(id) ON DELETE CASCADE},

q{ALTER TABLE element__site ADD 
    CONSTRAINT fk_element__element__site__element__id  FOREIGN KEY (element__id)
    REFERENCES element(id) ON DELETE CASCADE},

q{ALTER TABLE element__site ADD
    CONSTRAINT fk_output_channel__element__site FOREIGN KEY (primary_oc__id)
    REFERENCES output_channel(id) ON DELETE CASCADE},

q{INSERT INTO element__site (element__id, site__id, primary_oc__id) SELECT e.id, 100, primary_oc__id
    FROM element AS e, at_type AS a WHERE a.id = e.type__id AND a.top_level = 1},

#q{ALTER TABLE element DROP CONSTRAINT fk_output_channel__element}, # seens broken with 7.2.3
q{ALTER TABLE element RENAME COLUMN primary_oc__id TO primary_oc__id__old},

q{DROP INDEX fkx_output_channel__element},
  ;



1;
__END__

