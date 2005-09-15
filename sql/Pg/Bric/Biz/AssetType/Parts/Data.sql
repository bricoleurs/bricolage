-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate$
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Garth Webb <garth@perijove.com>
--
-- The sql to create the element_data table.
-- This maps to the Bric::AssetType::Parts::Data class.
-- Related tables are element and element_container
--

-- -----------------------------------------------------------------------------
-- Sequences

-- Unique IDs for the element_data table
CREATE SEQUENCE seq_at_data START 1024;

-- Unique IDs for the attr_element_data table
CREATE SEQUENCE seq_attr_at_data START 1024;

-- Unique IDs for each attr_element_data_*_val table
CREATE SEQUENCE seq_attr_at_data_val START 1024;

-- Unique IDs for the element_data_meta table
CREATE SEQUENCE seq_attr_at_data_meta START 1024;

-- -----------------------------------------------------------------------------
-- Table: element_data
--
-- Description:	This is the table that contains the name and rules for 
-- 		element fields.   It contains references to the 
--		element table and to the element_container table
--		( parent_id field ).   The place field represents the order
-- 		that this is to be represented with in it's container.
--
--If the element_meta field is set then all the properties are taken from
--	That.    Or maybe not, get feed back on this.
-- 	Define constraint on repeatable and sql_type


CREATE TABLE at_data (
    id               INTEGER         NOT NULL
                                     DEFAULT NEXTVAL('seq_element'),
    element__id      INTEGER         NOT NULL,
    name             VARCHAR(32)     NOT NULL,
    key_name         VARCHAR(32)     NOT NULL,
    description      VARCHAR(256),
    place            INTEGER         NOT NULL,
    required         BOOLEAN         NOT NULL DEFAULT FALSE,
    quantifier       VARCHAR(2)      NOT NULL,
    autopopulated    BOOLEAN         NOT NULL DEFAULT FALSE,
    map_type__id     INTEGER,
    publishable      BOOLEAN         NOT NULL DEFAULT FALSE,
    max_length       INTEGER         NOT NULL DEFAULT 0,
    sql_type         VARCHAR(30)     NOT NULL DEFAULT 'short',
    field_type       VARCHAR(30)     NOT NULL DEFAULT 'text',
    precision        SMALLINT,
    cols             INTEGER         NOT NULL,
    rows             INTEGER         NOT NULL,
    length           INTEGER         NOT NULL,
    vals             TEXT,
    multiple         BOOLEAN         NOT NULL DEFAULT FALSE,
    default_val      TEXT,
    active           BOOLEAN         NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_at_data__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table: attr_element_data
--
-- Description: A table to represent types of attributes.  A type is defined by
--              its subsystem, its element_data ID and an attribute name.

CREATE TABLE attr_at_data (
    id         INTEGER       NOT NULL
                             DEFAULT NEXTVAL('seq_attr_at_data'),
    subsys     VARCHAR(256)  NOT NULL,
    name       VARCHAR(256)  NOT NULL,
    sql_type   VARCHAR(30)   NOT NULL,
    active     BOOLEAN       NOT NULL DEFAULT TRUE,
   CONSTRAINT pk_attr_at_data__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table: attr_element_data_val
--
-- Description: A table to hold attribute values.

CREATE TABLE attr_at_data_val (
    id           INTEGER         NOT NULL
                                 DEFAULT NEXTVAL('seq_attr_at_data_val'),
    object__id   INTEGER         NOT NULL,
    attr__id     INTEGER         NOT NULL,
    date_val     TIMESTAMP,
    short_val    VARCHAR(1024),
    blob_val     TEXT,
    serial       BOOLEAN         DEFAULT FALSE,
    active       BOOLEAN         NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_attr_at_data_val__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table: attr_element_data_meta
--
-- Description: A table to represent metadata on types of attributes.

CREATE TABLE attr_at_data_meta (
    id        INTEGER         NOT NULL
                              DEFAULT NEXTVAL('seq_attr_at_data_meta'),
    attr__id  INTEGER         NOT NULL,
    name      VARCHAR(256)    NOT NULL,
    value     TEXT,
    active    BOOLEAN         NOT NULL DEFAULT TRUE,
   CONSTRAINT pk_attr_at_data_meta__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Indexes.
--

CREATE UNIQUE INDEX udx_atd__key_name__at_id ON at_data(lower_text_num(key_name, element__id));
CREATE INDEX udx_atd__name__at_id ON at_data(LOWER(name));
CREATE INDEX fkx_map_type__atd on at_data(map_type__id);
CREATE INDEX fkx_element__atd on at_data(element__id);

-- Unique index on subsystem/name pair
CREATE UNIQUE INDEX udx_attr_atd__subsys__name ON attr_at_data(subsys, name);

-- Indexes on name and subsys.
CREATE INDEX idx_attr_atd__name ON attr_at_data(LOWER(name));
CREATE INDEX idx_attr_atd__subsys ON attr_at_data(LOWER(subsys));

-- Unique index on object__id/attr__id pair
CREATE UNIQUE INDEX udx_attr_atd_val__obj_attr ON attr_at_data_val (object__id,attr__id);

-- FK indexes on object__id and attr__id.
CREATE INDEX fkx_atd__attr_atd_val ON attr_at_data_val(object__id);
CREATE INDEX fkx_attr_atd__attr_atd_val ON attr_at_data_val(attr__id);

-- Unique index on attr__id/name pair
CREATE UNIQUE INDEX udx_attr_atd_meta__attr_name ON attr_at_data_meta (attr__id, name);

-- Index on meta name.
CREATE INDEX idx_attr_atd_meta__name ON attr_at_data_meta(LOWER(name));

-- FK index on attr__id.
CREATE INDEX fkx_attr_atd__attr_atd_meta ON attr_at_data_meta(attr__id);


