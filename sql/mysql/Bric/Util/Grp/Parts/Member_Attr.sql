-- Project: Bricolage
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Michael Soderstrom <miraso@pacbell.net>
--
-- -----------------------------------------------------------------------------
--
-- This SQL creates the tables necessary for the attribute object.  This file
-- applies to attributes on the Bric::Util::Grp class.  Any other classes that 
-- require attributes need only duplicate these tables, changing 'member' to 
-- the correct class name.  Class names may be shortened to ensure that the
-- resulting table names are under the oracle 30 character name limit as long
-- as the resulting shortened class name is unique.
--

-- Table: attr_member
--
-- Description: A table to represent types of attributes.  A type is defined by
--              its subsystem, its member ID and an attribute name.

CREATE TABLE attr_member (
    id         INTEGER       NOT NULL AUTO_INCREMENT,
    subsys     VARCHAR(256)  NOT NULL,
    name       VARCHAR(256)  NOT NULL,
    sql_type   VARCHAR(30)   NOT NULL,
    active     BOOLEAN       NOT NULL DEFAULT TRUE,
   CONSTRAINT pk_attr_member__id PRIMARY KEY (id)
)
    ENGINE     InnoDB;

-- -------------------------------------------------------------------------------
-- Table: attr_member_val
-- Description: A table to hold attribute values.

CREATE TABLE attr_member_val (
    id           INTEGER         NOT NULL AUTO_INCREMENT,
    object__id   INTEGER         NOT NULL,
    attr__id     INTEGER         NOT NULL,
    date_val     DATETIME,
    short_val    VARCHAR(1024),
    blob_val     TEXT,
    serial       BOOLEAN         DEFAULT FALSE,
    active       BOOLEAN         NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_attr_member_val__id PRIMARY KEY (id)
)
    ENGINE     InnoDB;

-- -------------------------------------------------------------------------------
-- Table: attr_member_meta
-- Description: A table to represent metadata on types of attributes.

CREATE TABLE attr_member_meta (
    id        INTEGER         NOT NULL AUTO_INCREMENT,
    attr__id  INTEGER         NOT NULL,
    name      VARCHAR(256)    NOT NULL,
    value     VARCHAR(2048),
    active    BOOLEAN         NOT NULL DEFAULT TRUE,
   CONSTRAINT pk_attr_member_meta__id PRIMARY KEY (id)
)
    ENGINE     InnoDB;

-- -----------------------------------------------------------------------------
-- Indexes.
--

-- Unique index on subsystem/name pair
CREATE UNIQUE INDEX udx_attr_member__subsys__name ON attr_member(subsys(254), name(254));

-- Indexes on name and subsys.
CREATE INDEX idx_attr_member__name ON attr_member(name(254));
CREATE INDEX idx_attr_member__subsys ON attr_member(subsys(254));

-- Unique index on object__id/attr__id pair
CREATE UNIQUE INDEX udx_attr_member_val__obj_attr ON attr_member_val (object__id,attr__id);

-- FK indexes on object__id and attr__id.
CREATE INDEX fkx_member__attr_member_val ON attr_member_val(object__id);
CREATE INDEX fkx_attr_member__attr_member_val ON attr_member_val(attr__id);

-- Unique index on attr__id/name pair
CREATE UNIQUE INDEX udx_attr_member_meta__attr_name ON attr_member_meta (attr__id, name(254));

-- Index on meta name.
CREATE INDEX idx_attr_member_meta__name ON attr_member_meta(name(254));

-- FK index on attr__id.
CREATE INDEX fkx_attr_member__attr_member_meta ON attr_member_meta(attr__id);
