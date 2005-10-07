-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate$
--
-- This is the SQL that will create the element_type table.
-- It is related to the Bric::ElementType class.
-- Related tables are element and field
--
--

-- -----------------------------------------------------------------------------
-- Sequences

-- Unique IDs for the element table
CREATE SEQUENCE seq_element_type START 1024;

-- Unique IDs for the subelement table
--CREATE SEQUENCE seq_subelement_type START 1024;

-- Unique IDs for element__output_channel
CREATE SEQUENCE seq_element_type__output_channel START 1024;

-- Unique IDs for element__language
--CREATE SEQUENCE seq_element__language START 1024;

-- Unique IDs for element_member
CREATE SEQUENCE seq_element_type_member START 1024;

-- Unique IDs for the attr_element table
CREATE SEQUENCE seq_attr_element_type START 1024;

-- Unique IDs for each attr_element_*_val table
CREATE SEQUENCE seq_attr_element_type_val START 1024;

-- Unique IDs for the element_meta table
CREATE SEQUENCE seq_attr_element_type_meta START 1024;

-- Unique IDs for the element__site table.
CREATE SEQUENCE seq_element_type__site START 1024;

-- -----------------------------------------------------------------------------
-- Table: element_type
--
-- Description: The table that holds the information for a given asset type.  
--              Holds name and description information and is references by 
--              element_contaner and field_type rows.
--

CREATE TABLE element_type  (
    id              INTEGER        NOT NULL
                                   DEFAULT NEXTVAL('seq_element_type'),
    name            VARCHAR(64)    NOT NULL,
    key_name        VARCHAR(64)    NOT NULL,
    description     VARCHAR(256),
    top_level       BOOLEAN        NOT NULL DEFAULT FALSE,
    paginated       BOOLEAN        NOT NULL DEFAULT FALSE,
    fixed_uri       BOOLEAN        NOT NULL DEFAULT FALSE,
    related_story   BOOLEAN        NOT NULL DEFAULT FALSE,
    related_media   BOOLEAN        NOT NULL DEFAULT FALSE,
    media           BOOLEAN        NOT NULL DEFAULT FALSE,
    biz_class__id   INTEGER        NOT NULL,
    et_grp__id      INTEGER,
    type__id        INTEGER,
    active          BOOLEAN        NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_element_type__id PRIMARY KEY (id)
);

/*
-- -----------------------------------------------------------------------------
-- Table: subelement_type
--
-- Description: A table that manages element type parent/child relationships.
-- Here for future reference.
CREATE TABLE subelement_type  (
    id              INTEGER        NOT NULL
                                   DEFAULT NEXTVAL('seq_subelement_type'),
    parent_id       INTEGER        NOT NULL,
    child_id        INTEGER        NOT NULL,
    place           INTEGER        NOT NULL DEFAULT 1,
    min             INTEGER        NOT NULL DEFAULT 0,
    max             INTEGER        NOT NULL DEFAULT 0,
    CONSTRAINT pk_subelement_type__id PRIMARY KEY (id)
);

*/

-- -----------------------------------------------------------------------------
-- Table: element__site
--
-- Description: A table that maps 

CREATE TABLE element_type__site (
    id               INTEGER NOT NULL
                             DEFAULT NEXTVAL('seq_element_type__site'),
    element_type__id INTEGER NOT NULL,
    site__id         INTEGER NOT NULL,
    active           BOOLEAN NOT NULL DEFAULT TRUE,
    primary_oc__id   INTEGER NOT NULL,
    CONSTRAINT pk_element_type__site__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table: element__output_channel
--
-- Description: Holds a reference to the asset type table, the output channel 
--              table and an active flag
--

CREATE TABLE element_type__output_channel (
    id                  INTEGER    NOT NULL
                                   DEFAULT NEXTVAL('seq_element_type__output_channel'),
    element_type__id    INTEGER    NOT NULL,
    output_channel__id  INTEGER    NOT NULL,
    enabled             BOOLEAN    NOT NULL DEFAULT TRUE,
    active              BOOLEAN    NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_element_type__output_channel__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table: element_member
-- 
-- Description: The link between element objects and member objects
--

CREATE TABLE element_type_member (
    id          INTEGER  NOT NULL
                         DEFAULT NEXTVAL('seq_element_type_member'),
    object_id   INTEGER  NOT NULL,
    member__id  INTEGER  NOT NULL,
    CONSTRAINT pk_element_type_member__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table: attr_element
--
-- Description: A table to represent types of attributes.  A type is defined by
--              its subsystem, its element ID and an attribute name.

CREATE TABLE attr_element_type (
    id         INTEGER       NOT NULL
                             DEFAULT NEXTVAL('seq_attr_element_type'),
    subsys     VARCHAR(256)  NOT NULL,
    name       VARCHAR(256)  NOT NULL,
    sql_type   VARCHAR(30)   NOT NULL,
    active     BOOLEAN       NOT NULL DEFAULT TRUE,
   CONSTRAINT pk_attr_element_type__id PRIMARY KEY (id)
);


-- -----------------------------------------------------------------------------
-- Table: attr_element_val
--
-- Description: A table to hold attribute values.

CREATE TABLE attr_element_type_val (
    id           INTEGER      NOT NULL
                              DEFAULT NEXTVAL('seq_attr_element_type_val'),
    object__id   INTEGER      NOT NULL,
    attr__id     INTEGER      NOT NULL,
    date_val     TIMESTAMP,
    short_val    VARCHAR(1024),
    blob_val     TEXT,
    serial       BOOLEAN      DEFAULT FALSE,
    active       BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_attr_element_type_val__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table: attr_element_meta
--
-- Description: A table to represent metadata on types of attributes.

CREATE TABLE attr_element_type_meta (
    id        INTEGER         NOT NULL
                              DEFAULT NEXTVAL('seq_attr_element_type_meta'),
    attr__id  INTEGER         NOT NULL,
    name      VARCHAR(256)    NOT NULL,
    value     VARCHAR(2048),
    active    BOOLEAN         NOT NULL DEFAULT TRUE,
   CONSTRAINT pk_attr_element_type_meta__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Indexes.
--
CREATE UNIQUE INDEX udx_element_type__key_name ON element_type(LOWER(key_name));
CREATE INDEX fkx_et_type__element_type ON element_type(type__id);
CREATE INDEX fkx_grp__element_type ON element_type(et_grp__id);
CREATE INDEX fkx_class__element_type ON element_type(biz_class__id);

/* Subelement_type indexes for future reference.
CREATE INDEX fkx_element_type__subelement__parent_id ON subelement_type(parent_id);
CREATE INDEX fkx_element_type__subelement__child_id ON subelement_type(child_id);
CREATE UNIQUE INDEX udx_subelement_type__parent__child ON subelement_type(parent_id, child_id);

*/

CREATE UNIQUE INDEX udx_et_oc_id__et__oc_id ON element_type__output_channel(element_type__id, output_channel__id);
CREATE INDEX fkx_output_channel__et_oc ON element_type__output_channel(output_channel__id);
CREATE INDEX fkx_element__et_oc ON element_type__output_channel(element_type__id);

CREATE INDEX fkx_element_type__et_member ON element_type_member(object_id);
CREATE INDEX fkx_member__et_member ON element_type_member(member__id);

CREATE UNIQUE INDEX udx_element_type__site on element_type__site(element_type__id, site__id);


-- Unique index on subsystem/name pair
CREATE UNIQUE INDEX udx_attr_et__subsys__name ON attr_element_type(subsys, name);

-- Indexes on name and subsys.
CREATE INDEX idx_attr_et__name ON attr_element_type(LOWER(name));
CREATE INDEX idx_attr_et__subsys ON attr_element_type(LOWER(subsys));

-- Unique index on object__id/attr__id pair
CREATE UNIQUE INDEX udx_attr_et_val__obj_attr ON attr_element_type_val (object__id, attr__id);

-- FK indexes on object__id and attr__id.
CREATE INDEX fkx_et__attr_et_val ON attr_element_type_val(object__id);
CREATE INDEX fkx_attr_et__attr_et_val ON attr_element_type_val(attr__id);

-- Unique index on attr__id/name pair
CREATE UNIQUE INDEX udx_attr_et_meta__attr_name ON attr_element_type_meta (attr__id, name);

-- Index on meta name.
CREATE INDEX idx_attr_et_meta__name ON attr_element_type_meta(LOWER(name));

-- FK index on attr__id.
CREATE INDEX fkx_attr_et__attr_et_meta ON attr_element_type_meta(attr__id);

-- FK index on element__site.
CREATE INDEX fkx_et__et__site__element_type__id ON element_type__site(element_type__id);
CREATE INDEX fkx_site__et__site__site__id ON element_type__site(site__id);
CREATE INDEX fkx_output_channel__et__site ON element_type__site(primary_oc__id);
