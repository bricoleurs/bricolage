-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate$
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Michael Soderstrom <miraso@pacbell.net>
--
-- -----------------------------------------------------------------------------
--
-- This SQL creates the tables necessary for the attribute object.  This file
-- applies to attributes on the Bric::Util::Grp class.  Any other classes that 
-- require attributes need only duplicate these tables, changing 'grp' to 
-- the correct class name.  Class names may be shortened to ensure that the
-- resulting table names are under the oracle 30 character name limit as long
-- as the resulting shortened class name is unique.
--

-- -------------------------------------------------------------------------------
-- Sequences

-- Unique IDs for the attr_grp table
CREATE SEQUENCE seq_attr_grp START  1024;

-- Unique IDs for each attr_grp_*_val table
CREATE SEQUENCE seq_attr_grp_val START  1024;

-- Unique IDs for the grp_meta table
CREATE SEQUENCE seq_attr_grp_meta START  1024;

-- Table: attr_grp
--
-- Description: A table to represent types of attributes.  A type is defined by
--              its subsystem, its grp ID and an attribute name.

CREATE TABLE attr_grp (
    id         NUMERIC(10)   NOT NULL
                             DEFAULT NEXTVAL('seq_attr_grp'),
    subsys     VARCHAR(256)  NOT NULL,
    name       VARCHAR(256)  NOT NULL,
    sql_type   VARCHAR(30)   NOT NULL,
    active     NUMERIC(1)    DEFAULT 1
                             NOT NULL
                             CONSTRAINT ck_attr_grp__active CHECK (active IN (0,1)),
   CONSTRAINT pk_attr_grp__id PRIMARY KEY (id)
);

-- -------------------------------------------------------------------------------
-- Table: attr_grp_val
--
-- Description: A table to hold attribute values.


CREATE TABLE attr_grp_val (
    id           NUMERIC(10)     NOT NULL
                                 DEFAULT NEXTVAL('seq_attr_grp_val'),
    object__id   NUMERIC(10)     NOT NULL,
    attr__id     NUMERIC(10)     NOT NULL,
    date_val     TIMESTAMP,
    short_val    VARCHAR(1024),
    blob_val     TEXT,
    serial       NUMERIC(1)      DEFAULT 0,
    active       NUMERIC(1)      DEFAULT 1
                                 NOT NULL
                                 CONSTRAINT ck_attr_grp_val__active CHECK (active IN (0,1)),
    CONSTRAINT pk_attr_grp_val__id PRIMARY KEY (id)
);


-- -------------------------------------------------------------------------------
-- Table: attr_grp_meta
--
-- Description: A table to represent metadata on types of attributes.

CREATE TABLE attr_grp_meta (
    id        NUMERIC(10)     NOT NULL
                              DEFAULT NEXTVAL('seq_attr_grp_meta'),
    attr__id  NUMERIC(10)     NOT NULL,
    name      VARCHAR(256)    NOT NULL,
    value     VARCHAR(2048),
    active    NUMERIC(1)      DEFAULT 1
                              NOT NULL
                              CONSTRAINT ck_attr_grp_meta__active CHECK (active IN (0,1)),
   CONSTRAINT pk_attr_grp_meta__id PRIMARY KEY (id)
);


-- -----------------------------------------------------------------------------
-- Indexes.
--

-- Unique index on subsystem/name pair
CREATE UNIQUE INDEX udx_attr_grp__subsys__name ON attr_grp(subsys, name);

-- Indexes on name and subsys.
CREATE INDEX idx_attr_grp__name ON attr_grp(LOWER(name));
CREATE INDEX idx_attr_grp__subsys ON attr_grp(LOWER(subsys));

-- Unique index on object__id/attr__id pair
CREATE UNIQUE INDEX udx_attr_grp_val__obj_attr ON attr_grp_val (object__id,attr__id);

-- FK indexes on object__id and attr__id.
CREATE INDEX fkx_grp__attr_grp_val ON attr_grp_val(object__id);
CREATE INDEX fkx_attr_grp__attr_grp_val ON attr_grp_val(attr__id);

-- Unique index on attr__id/name pair
CREATE UNIQUE INDEX udx_attr_grp_meta__attr_name ON attr_grp_meta (attr__id, name);

-- Index on meta name.
CREATE INDEX idx_attr_grp_meta__name ON attr_grp_meta(LOWER(name));

-- FK index on attr__id.
CREATE INDEX fkx_attr_grp__attr_grp_meta ON attr_grp_meta(attr__id);


