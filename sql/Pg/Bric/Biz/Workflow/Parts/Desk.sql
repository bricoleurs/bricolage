-- Project: Bricolage
--
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
    id              INTEGER       NOT NULL
                                  DEFAULT NEXTVAL('seq_desk'),
    name            VARCHAR(64)   NOT NULL,
    description     VARCHAR(256),
    pre_chk_rules   INTEGER,
    post_chk_rules  INTEGER,
    asset_grp       INTEGER,
    publish         BOOLEAN       NOT NULL DEFAULT FALSE,
    active          BOOLEAN        NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_desk__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table: desk_member
-- 
-- Description: The link between desk objects and member objects
--

CREATE TABLE desk_member (
    id          INTEGER        NOT NULL
                               DEFAULT NEXTVAL('seq_desk_member'),
    object_id   INTEGER        NOT NULL,
    member__id  INTEGER        NOT NULL,
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


