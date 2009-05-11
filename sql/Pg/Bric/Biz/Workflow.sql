-- Project: Bricolage
--
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
    id               INTEGER      NOT NULL
                                  DEFAULT NEXTVAL('seq_workflow'),
    name             VARCHAR(64)  NOT NULL,
    description      VARCHAR(256) NOT NULL,

    all_desk_grp_id  INTEGER      NOT NULL,
    req_desk_grp_id  INTEGER      NOT NULL,
    asset_grp_id     INTEGER      NOT NULL,
    head_desk_id     INTEGER      NOT NULL,
    type             INT2         NOT NULL
                                  DEFAULT 1
                                  CONSTRAINT ck_workflow__type
                                    CHECK (type IN (1,2,3)),
    active           BOOLEAN        NOT NULL DEFAULT TRUE,
    site__id         INTEGER      NOT NULL,
    CONSTRAINT pk_workflow__id PRIMARY KEY (id)
);

--
-- TABLE: workflow_member
--

CREATE TABLE workflow_member (
    id          INTEGER        NOT NULL
                               DEFAULT NEXTVAL('seq_workflow_member'),
    object_id   INTEGER        NOT NULL,
    member__id  INTEGER        NOT NULL,
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


