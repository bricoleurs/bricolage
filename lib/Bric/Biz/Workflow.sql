-- Project: Bricolage
-- VERSION: $Revision: 1.2 $
--
-- $Date: 2001-10-09 20:48:53 $
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
    head_desk_id     NUMERIC(10)  NOT NULL,
    type             NUMERIC(1)   NOT NULL,
    active           NUMERIC(1)	  NOT NULL
                                  DEFAULT 1
                                  CONSTRAINT ck_workflow__active
                                    CHECK (active IN (0,1)),
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
CREATE UNIQUE INDEX udx_workflow__name ON workflow(LOWER(name));
CREATE INDEX fkx_workflow__workflow_member ON workflow_member(object_id);
CREATE INDEX fkx_member__workflow_member ON workflow_member(member__id);


