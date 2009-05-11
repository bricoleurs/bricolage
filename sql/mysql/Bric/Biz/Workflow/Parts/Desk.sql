-- Project: Bricolage
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Garth Webb <garth@perijove.com>
--
-- The database tables for the Bric::Workflow::Parts::Desk class.
--

-- -----------------------------------------------------------------------------
-- Table: desk
--
-- Description: Represents a desk in the workflow

CREATE TABLE desk (
    id              INTEGER       NOT NULL AUTO_INCREMENT,
    name            VARCHAR(64)   NOT NULL,
    description     VARCHAR(256),
    pre_chk_rules   INTEGER,
    post_chk_rules  INTEGER,
    asset_grp       INTEGER,
    publish         BOOLEAN       NOT NULL DEFAULT FALSE,
    active          BOOLEAN        NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_desk__id PRIMARY KEY (id)
)
    ENGINE          InnoDB
    AUTO_INCREMENT  1024;

-- -----------------------------------------------------------------------------
-- Table: desk_member
-- 
-- Description: The link between desk objects and member objects
--

CREATE TABLE desk_member (
    id          INTEGER        NOT NULL AUTO_INCREMENT,
    object_id   INTEGER        NOT NULL,
    member__id  INTEGER        NOT NULL,
    CONSTRAINT pk_desk_member__id PRIMARY KEY (id)
)
    ENGINE          InnoDB
    AUTO_INCREMENT  1024;


--
-- INDEXES.
--
CREATE UNIQUE INDEX udx_desk__name ON desk(name(64));
CREATE INDEX fkx_asset_grp__desk ON desk(asset_grp);
CREATE INDEX fkx_pre_grp__desk ON desk(pre_chk_rules);
CREATE INDEX fkx_post_grp__desk ON desk(post_chk_rules);

CREATE INDEX fkx_desk__desk_member ON desk_member(object_id);
CREATE INDEX fkx_member__desk_member ON desk_member(member__id);

--
-- AUTO_INCREMENT;
-- http://bugs.mysql.com/bug.php?id=21404
--

ALTER TABLE desk AUTO_INCREMENT 1024;
ALTER TABLE desk_member AUTO_INCREMENT 1024;
