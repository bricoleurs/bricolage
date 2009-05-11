-- Project: Bricolage
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Garth Webb <garth@perijove.com>
--
-- This SQL creates the tables necessary for the attribute object.  This file
-- applies to attributes on the Bric::Person class.  Any other classes that 
-- require attributes need only duplicate these tables, changing 'person' to 
-- the correct class name.  Class names may be shortened to ensure that the
-- resulting table names are under the oracle 30 character name limit as long
-- as the resulting shortened class name is unique.
--


-- -----------------------------------------------------------------------------
-- Table: category
-- 
-- Description: The category table
--

CREATE TABLE category (
    id               INTEGER         NOT NULL AUTO_INCREMENT, 
    site__id         INTEGER         NOT NULL,
    directory        VARCHAR(128)    NOT NULL,
    uri              VARCHAR(256)    NOT NULL,
    name             VARCHAR(128),
    description      VARCHAR(256),
    parent_id        INTEGER         NOT NULL,
    asset_grp_id     INTEGER         NOT NULL,
    active           BOOLEAN         NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_category__id PRIMARY KEY (id)
)
    ENGINE           InnoDB
    AUTO_INCREMENT   1024;


-- -----------------------------------------------------------------------------
-- Table: category_member
-- 
-- Description: The link between desk objects and member objects
--

CREATE TABLE category_member (
    id          INTEGER  NOT NULL AUTO_INCREMENT, 
    object_id   INTEGER  NOT NULL,
    member__id  INTEGER  NOT NULL,
    CONSTRAINT pk_category_member__id PRIMARY KEY (id)
)
    ENGINE           InnoDB
    AUTO_INCREMENT   1024;


-- -----------------------------------------------------------------------------
-- Table: attr_category
--
-- Description: A table to represent types of attributes.  A type is defined by
--              its subsystem, its category ID and an attribute name.

CREATE TABLE attr_category (
    id         INTEGER       NOT NULL AUTO_INCREMENT, 
    subsys     VARCHAR(256)  NOT NULL,
    name       VARCHAR(256)  NOT NULL,
    sql_type   VARCHAR(30)   NOT NULL,
    active     BOOLEAN       NOT NULL DEFAULT TRUE,
   CONSTRAINT pk_attr_category__id PRIMARY KEY (id)
)
    ENGINE           InnoDB
    AUTO_INCREMENT   1024;




-- -----------------------------------------------------------------------------
-- Table: attr_category_val
--
-- Description: A table to hold attribute values.

CREATE TABLE attr_category_val (
    id           INTEGER         NOT NULL AUTO_INCREMENT, 
    object__id   INTEGER         NOT NULL,
    attr__id     INTEGER         NOT NULL,
    date_val     DATETIME,
    short_val    VARCHAR(1024),
    blob_val     TEXT,
    serial       BOOLEAN         DEFAULT FALSE,
    active       BOOLEAN         NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_attr_category_val__id PRIMARY KEY (id)
)
    ENGINE           InnoDB
    AUTO_INCREMENT   1024;



-- -----------------------------------------------------------------------------
-- Table: attr_category_meta
--
-- Description: A table to represent metadata on types of attributes.

CREATE TABLE attr_category_meta (
    id        INTEGER         NOT NULL AUTO_INCREMENT, 
    attr__id  INTEGER         NOT NULL,
    name      VARCHAR(256)    NOT NULL,
    value     VARCHAR(2048),
    active    BOOLEAN         NOT NULL DEFAULT TRUE,
   CONSTRAINT pk_attr_category_meta__id PRIMARY KEY (id)
)
    ENGINE           InnoDB
    AUTO_INCREMENT   1024;



-- -----------------------------------------------------------------------------
-- Indexes.
--
CREATE INDEX idx_category__directory ON category(directory);
CREATE UNIQUE INDEX udx_category__site_uri ON category(site__id, uri(255));
CREATE INDEX idx_category__uri ON category(uri);
CREATE INDEX idx_category__lower_uri ON category(uri);
CREATE INDEX idx_category__name ON category(name);
CREATE INDEX idx_category__parent_id ON category(parent_id);
CREATE INDEX fkx_asset_grp__category ON category(asset_grp_id);

CREATE INDEX fkx_category__category_member ON category_member(object_id);
CREATE INDEX fkx_member__category_member ON category_member(member__id);
CREATE INDEX fkx_category__site ON category(site__id);

-- Unique index on subsystem/name pair
CREATE UNIQUE INDEX udx_attr_cat__subsys__name ON attr_category(subsys(255), name(255));

-- Indexes on name and subsys.
CREATE INDEX idx_attr_cat__name ON attr_category(name);
CREATE INDEX idx_attr_cat__subsys ON attr_category(subsys);

-- Unique index on object__id/attr__id pair
CREATE UNIQUE INDEX udx_attr_cat_val__obj_attr ON attr_category_val (object__id,attr__id);

-- FK indexes on object__id and attr__id.
CREATE INDEX fkx_cat__attr_cat_val ON attr_category_val(object__id);
CREATE INDEX fkx_attr_cat__attr_cat_val ON attr_category_val(attr__id);

-- Unique index on attr__id/name pair
CREATE UNIQUE INDEX udx_attr_cat_meta__attr_name ON attr_category_meta (attr__id, name(255));

-- Index on meta name.
CREATE INDEX idx_attr_cat_meta__name ON attr_category_meta(name);

-- FK index on attr__id.
CREATE INDEX fkx_attr_cat__attr_cat_meta ON attr_category_meta(attr__id);


--
-- AUTO_INCREMENT;
-- http://bugs.mysql.com/bug.php?id=21404
--

ALTER TABLE category AUTO_INCREMENT 1024;
ALTER TABLE category_member AUTO_INCREMENT 1024;
ALTER TABLE attr_category AUTO_INCREMENT 1024;
ALTER TABLE attr_category_val AUTO_INCREMENT 1024;
ALTER TABLE attr_category_meta AUTO_INCREMENT 1024;
