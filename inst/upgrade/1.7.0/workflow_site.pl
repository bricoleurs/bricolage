#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

exit if test_sql(qq{SELECT site__id FROM workflow});

do_sql
q{ DROP INDEX udx_workflow__name},
q{ DROP INDEX pk_workflow__id},
q {ALTER TABLE workflow RENAME TO upgrade_workflow},



q{ CREATE TABLE workflow (
    id               NUMERIC(10)  NOT NULL
                                  DEFAULT NEXTVAL('seq_workflow'),
    name             VARCHAR(64)  NOT NULL,
    description      VARCHAR(256) NOT NULL,
    all_desk_grp_id  NUMERIC(10)  NOT NULL,
    req_desk_grp_id  NUMERIC(10)  NOT NULL,
    head_desk_id     NUMERIC(10)  NOT NULL,
    type             NUMERIC(1)   NOT NULL,
    active           NUMERIC(1)	  NOT NULL
                                  DEFAULT 1
                                  CONSTRAINT ck_workflow__active
                                    CHECK (active IN (0,1)),
    site__id         NUMERIC(10)  NOT NULL,
    CONSTRAINT pk_workflow__id PRIMARY KEY (id)
)},

q{ INSERT INTO workflow SELECT *,100 FROM upgrade_workflow},

q{ DROP TABLE upgrade_workflow},

q{ CREATE INDEX fkx_site__workflow__site__id ON workflow(site__id)},

q{ ALTER TABLE    workflow
ADD CONSTRAINT fk_site__workflow__site__id FOREIGN KEY (site__id)
REFERENCES     site(id) ON DELETE CASCADE},

;

