-- Project: Bricolage
-- VERSION: $Revision: 1.1 $
--
-- $Date: 2001-09-06 21:54:18 $
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Garth Webb <garth@perijove.com>
--
-- The database tables for the Bric::Workflow::Parts::Desk class.
--

-- -----------------------------------------------------------------------------
-- Sequences

-- A sequence of unique IDs for the desk table.
CREATE SEQUENCE seq_desk START  1024;

-- Unique IDs for the desk member ordering.
CREATE SEQUENCE seq_desk_member START  1024;

-- -----------------------------------------------------------------------------
-- Table: desk
--
-- Description: Represents a desk in the workflow

CREATE TABLE desk (
    id              NUMERIC(10)   NOT NULL
                                  DEFAULT NEXTVAL('seq_desk'),
    name            VARCHAR(64)   NOT NULL,
    description     VARCHAR(256),
    pre_chk_rules   NUMERIC(10),
    post_chk_rules  NUMERIC(10),
    asset_grp       NUMERIC(10),
    publish         NUMERIC(1)    NOT NULL
                                  DEFAULT 0
                                  CONSTRAINT ck_desk__publish
                                    CHECK (publish IN (0,1)),
    active          NUMERIC(1)	  NOT NULL
                                  DEFAULT 1
                                  CONSTRAINT ck_desk__active
                                    CHECK (active IN (0,1)),
    CONSTRAINT pk_desk__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table: desk_member
-- 
-- Description: The link between desk objects and member objects
--

CREATE TABLE desk_member (
    id          NUMERIC(10,0)  NOT NULL
                               DEFAULT NEXTVAL('seq_desk_member'),
    object_id   NUMERIC(10,0)  NOT NULL,
    member__id  NUMERIC(10,0)  NOT NULL,
    CONSTRAINT pk_desk_member__id PRIMARY KEY (id)
);


--
-- INDEXES.
--
CREATE UNIQUE INDEX udx_desk__name ON desk(LOWER(name));
CREATE INDEX fkx_asset_grp__desk ON desk(asset_grp);
CREATE INDEX fkx_pre_grp__desk ON desk(pre_chk_rules);
CREATE INDEX fkx_post_grp__desk ON desk(post_chk_rules);

CREATE INDEX fkx_desk__desk_member ON desk_member(object_id);
CREATE INDEX fkx_member__desk_member ON desk_member(member__id);


/*
Change Log:
$Log: Desk.sql,v $
Revision 1.1  2001-09-06 21:54:18  wheeler
Initial revision

*/