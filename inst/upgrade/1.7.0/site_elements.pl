#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

exit if fetch_sql(qq{SELECT 1 FROM element__site});

do_sql

q{CREATE TABLE element__site (
    element__id    NUMERIC(10)  NOT NULL,
    site__id       NUMERIC(10)  NOT NULL,
    active         NUMERIC(1)   DEFAULT 1
                                NOT NULL
                                CONSTRAINT ck_site_element__active CHECK (active IN (0,1))
)},

q{CREATE UNIQUE INDEX udx_element__site on element__site(element__id, site__id)},

q{ALTER TABLE element__site ADD
    CONSTRAINT fk_element__site_site__id FOREIGN KEY (site__id)
    REFERENCES site(id) ON DELETE CASCADE},

q{ALTER TABLE element__site ADD 
    CONSTRAINT fk_element__site_element__id  FOREIGN KEY (element__id)
    REFERENCES element(id) ON DELETE CASCADE},

q{INSERT INTO element__site (element__id, site__id) SELECT e.id, 100 
FROM element AS e, at_type AS a WHERE a.id = e.type__id AND a.top_level = 1},

  ;

1;
__END__

