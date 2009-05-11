-- Project: Bricolage
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Garth Webb <garth@perijove.com>
--
-- The sql to create the field_type table.
-- This maps to the Bric::ElementType::Parts::FieldType class.
--

-- -----------------------------------------------------------------------------
-- Table: field_type
--
-- Description: This is the table that contains the name and rules for fields
--         types. It contains references to the element_type table. The place
--         column represents the order that this is to be represented with in
--         its container.
--


CREATE TABLE field_type (
    id               INTEGER         NOT NULL AUTO_INCREMENT,
    element_type__id INTEGER         NOT NULL,
    name             TEXT            NOT NULL,
    key_name         TEXT            NOT NULL,
    description      TEXT,
    place            INTEGER         NOT NULL,
    min_occurrence   INTEGER         NOT NULL DEFAULT 0,
    max_occurrence   INTEGER         NOT NULL DEFAULT 0,
    autopopulated    BOOLEAN         NOT NULL DEFAULT FALSE,
    max_length       INTEGER         NOT NULL DEFAULT 0,
    sql_type         VARCHAR(30)     NOT NULL DEFAULT 'short',
    widget_type      VARCHAR(30)     NOT NULL DEFAULT 'text',
    "precision"        SMALLINT,
    cols             INTEGER         NOT NULL,
    rows             INTEGER         NOT NULL,
    length           INTEGER         NOT NULL,
    vals             TEXT,
    multiple         BOOLEAN         NOT NULL DEFAULT FALSE,
    default_val      TEXT,
    active           BOOLEAN         NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_field_type__id PRIMARY KEY (id)
)
    ENGINE           InnoDB
    AUTO_INCREMENT   1024;

-- -----------------------------------------------------------------------------
-- Table: attr_field_type
--
-- Description: A table to represent types of attributes. A type is defined by
--              its subsystem, its field_type ID and an attribute name.

CREATE TABLE attr_field_type (
    id         INTEGER       NOT NULL AUTO_INCREMENT,
    subsys     VARCHAR(256)  NOT NULL,
    name       VARCHAR(256)  NOT NULL,
    sql_type   VARCHAR(30)   NOT NULL,
    active     BOOLEAN       NOT NULL DEFAULT TRUE,
   CONSTRAINT pk_attr_field_type__id PRIMARY KEY (id)
)
    ENGINE InnoDB
    AUTO_INCREMENT 1024;

-- -----------------------------------------------------------------------------
-- Table: attr_field_type_val
--
-- Description: A table to hold attribute values.

CREATE TABLE attr_field_type_val (
    id           INTEGER         NOT NULL AUTO_INCREMENT,
    object__id   INTEGER         NOT NULL,
    attr__id     INTEGER         NOT NULL,
    date_val     DATETIME,
    short_val    VARCHAR(1024),
    blob_val     TEXT,
    serial       BOOLEAN         DEFAULT FALSE,
    active       BOOLEAN         NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_attr_field_type_val__id PRIMARY KEY (id)
)
    ENGINE InnoDB
    AUTO_INCREMENT 1024;

-- -----------------------------------------------------------------------------
-- Table: attr_field_type_meta
--
-- Description: A table to represent metadata on types of attributes.

CREATE TABLE attr_field_type_meta (
    id        INTEGER         NOT NULL AUTO_INCREMENT,
    attr__id  INTEGER         NOT NULL,
    name      VARCHAR(256)    NOT NULL,
    value     TEXT,
    active    BOOLEAN         NOT NULL DEFAULT TRUE,
   CONSTRAINT pk_attr_field_type_meta__id PRIMARY KEY (id)
)
    ENGINE InnoDB
    AUTO_INCREMENT 1024;

-- -----------------------------------------------------------------------------
-- Indexes.
--

CREATE UNIQUE INDEX udx_field_type__key_name__et_id ON field_type(key_name(254), element_type__id);
CREATE INDEX idx_field_type__name__at_id ON field_type(name(254));
CREATE INDEX fkx_element_type__field_type on field_type(element_type__id);

-- Unique index on subsystem/name pair
CREATE UNIQUE INDEX udx_attr_field_type__subsys__name ON attr_field_type(subsys(254), name(254));

-- Indexes on name and subsys.
CREATE INDEX idx_attr_field_type__name ON attr_field_type(name(254));
CREATE INDEX idx_attr_field_type__subsys ON attr_field_type(subsys(254));

-- Unique index on object__id/attr__id pair
CREATE UNIQUE INDEX udx_attr_field_type_val__obj_attr ON attr_field_type_val (object__id, attr__id);

-- FK indexes on object__id and attr__id.
CREATE INDEX fkx_field_type__attr_field_type_val ON attr_field_type_val(object__id);
CREATE INDEX fkx_attr_field_type__attr_field_type_val ON attr_field_type_val(attr__id);

-- Unique index on attr__id/name pair
CREATE UNIQUE INDEX udx_attr_field_type_meta__attr_name ON attr_field_type_meta (attr__id, name(254));

-- Index on meta name.
CREATE INDEX idx_attr_field_type_meta__name ON attr_field_type_meta(name(254));

-- FK index on attr__id.
CREATE INDEX fkx_attr_field_type__attr_field_type_meta ON attr_field_type_meta(attr__id);

--
-- AUTO_INCREMENT;
-- http://bugs.mysql.com/bug.php?id=21404
--

ALTER TABLE field_type AUTO_INCREMENT 1024;
ALTER TABLE attr_field_type AUTO_INCREMENT 1024;
ALTER TABLE attr_field_type_val AUTO_INCREMENT 1024;
ALTER TABLE attr_field_type_meta AUTO_INCREMENT 1024;
