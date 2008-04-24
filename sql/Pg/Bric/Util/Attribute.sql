-- Project: Bricolage
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Garth Webb <garth@perijove.com>
--
-- -----------------------------------------------------------------------------
-- Attribute.sql
--
--
-- This SQL creates the tables necessary for the attribute object.  This file
-- applies to attributes on the Bric::Person class.  Any other classes that 
-- require attributes need only duplicate these tables, changing 'person' to 
-- the correct class name.  Class names may be shortened to ensure that the
-- resulting table names are under the oracle 30 character name limit as long
-- as the resulting shortened class name is unique.
--

/* Commented out because attr_person won't be used in production (in this version).
   However, the examples still apply. --David, 23 Feb 2001

-- -----------------------------------------------------------------------------
-- Sequences

-- Unique IDs for the attr_person table
CREATE SEQUENCE seq_attr_person START 1024;

-- Unique IDs for each attr_person_*_val table
CREATE SEQUENCE seq_attr_person_val START 1024;

-- Unique IDs for the person_meta table
CREATE SEQUENCE seq_attr_person_meta START 1024;

-- -----------------------------------------------------------------------------
-- Table: attr_person
--
-- Description: A table to represent types of attributes.  A type is defined by
--              its subsystem, its person ID and an attribute name.

CREATE TABLE attr_person (
    id         INTEGER       NOT NULL
                             DEFAULT NEXTVAL('seq_attr_person'),
    subsys     VARCHAR(256)  NOT NULL,
    name       VARCHAR(256)  NOT NULL,
    sql_type   VARCHAR(30)   NOT NULL,
    active     BOOLEAN       NOT NULL DEFAULT TRUE,
   CONSTRAINT pk_attr_person__id PRIMARY KEY (id)
);


-- -----------------------------------------------------------------------------
-- Table: attr_person_val
--
-- Description: A table to hold attribute values.

CREATE TABLE attr_person_val (
    id           INTEGER         NOT NULL
                                 DEFAULT NEXTVAL('seq_attr_person_val'),
    object__id   INTEGER         NOT NULL,
    attr__id     INTEGER         NOT NULL,
    date_val     TIMESTAMP,
    short_val    VARCHAR(1024),
    blob_val     TEXT,
    serial       BOOLEAN         DEFAULT FALSE,
    active       BOOLEAN         NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_attr_person_val__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table: attr_person_meta
--
-- Description: A table to represent metadata on types of attributes.

CREATE TABLE attr_person_meta (
    id        INTEGER         NOT NULL
                              DEFAULT NEXTVAL('seq_attr_person_meta'),
    attr__id  INTEGER         NOT NULL,
    name      VARCHAR(256)    NOT NULL,
    value     VARCHAR(2048),
    active    BOOLEAN         NOT NULL DEFAULT TRUE,
   CONSTRAINT pk_attr_person_meta__id PRIMARY KEY (id)
);


-- -----------------------------------------------------------------------------
-- Indexes.
--

-- Unique index on subsystem/name pair
CREATE UNIQUE INDEX udx_attr_person__subsys__name ON attr_person(subsys, name);

-- Indexes on name and subsys.
CREATE INDEX idx_attr_person__name ON attr_person(LOWER(name));
CREATE INDEX idx_attr_person__subsys ON attr_person(LOWER(subsys));

-- Unique index on object__id/attr__id pair
CREATE UNIQUE INDEX udx_attr_person_val__obj_attr ON attr_person_val (object__id,attr__id);

-- FK indexes on object__id and attr__id.
CREATE INDEX fkx_person__attr_person_val ON attr_person_val(object__id);
CREATE INDEX fkx_attr_person__attr_person_val ON attr_person_val(attr__id);

-- Unique index on attr__id/name pair
CREATE UNIQUE INDEX udx_attr_person_meta__attr_name ON attr_person_meta (attr__id, name);

-- Index on meta name.
CREATE INDEX idx_attr_person_meta__name ON attr_person_meta(LOWER(name));

-- FK index on attr__id.
CREATE INDEX fkx_attr_person__attr_person_meta ON attr_person_meta(attr__id);

*/


