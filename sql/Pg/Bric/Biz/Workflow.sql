-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate$
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Garth Webb <garth@perijove.com>
--
-- The database tables for the Workflow class.
--

-- -----------------------------------------------------------------------------
-- Sequences

-- A sequence of unique IDs for the workflow table.
CREATE SEQUENCE seq_workflow START  1024;
CREATE SEQUENCE seq_workflow_member START 1024;

-- -----------------------------------------------------------------------------
-- Table: workflow
--
-- Description: The main workflow table.

CREATE TABLE workflow (
    id               NUMERIC(10)  NOT NULL
                                  DEFAULT NEXTVAL('seq_workflow'),
    name             VARCHAR(64)  NOT NULL,
    description      VARCHAR(256) NOT NULL,
    all_desk_grp_id  NUMERIC(10)  NOT NULL,
    req_desk_grp_id  NUMERIC(10)  NOT NULL,
    asset_grp_id     NUMERIC(10)  NOT NULL,
    head_desk_id     NUMERIC(10)  NOT NULL,
    type             NUMERIC(1)   NOT NULL
                                  DEFAULT 1
                                  CONSTRAINT ck_workflow__type
                                    CHECK (type IN (1,2,3)),
    active           NUMERIC(1)	  NOT NULL
                                  DEFAULT 1
                                  CONSTRAINT ck_workflow__active
                                    CHECK (active IN (0,1)),
    site__id         NUMERIC(10)  NOT NULL,
    CONSTRAINT pk_workflow__id PRIMARY KEY (id)
);

--
-- TABLE: workflow_member
--

CREATE TABLE workflow_member (
    id          NUMERIC(10,0)  NOT NULL
                               DEFAULT NEXTVAL('seq_workflow_member'),
    object_id   NUMERIC(10,0)  NOT NULL,
    member__id  NUMERIC(10,0)  NOT NULL,
    CONSTRAINT pk_workflow_member__id PRIMARY KEY (id)
);


-- 
-- INDEXES.
--

CREATE UNIQUE INDEX udx_workflow__name__site__id
ON workflow(lower_text_num(name, site__id));
CREATE INDEX fkx_site__workflow__site__id ON workflow(site__id);
CREATE INDEX fkx_grp__workflow__all_desk_grp_id ON workflow(all_desk_grp_id);
CREATE INDEX fkx_grp__workflow__req_desk_grp_id ON workflow(req_desk_grp_id);
CREATE INDEX fkx_grp__workflow__asset_grp_id ON workflow(asset_grp_id);
CREATE INDEX fkx_workflow__workflow_member ON workflow_member(object_id);
CREATE INDEX fkx_member__workflow_member ON workflow_member(member__id);


