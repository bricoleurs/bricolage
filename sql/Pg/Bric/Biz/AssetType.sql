-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate$
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Garth Webb <garth@perijove.com>
--
-- This is the SQL that will create the element table.
-- It is related to the Bric::AssetType class.
-- Related tables are element_container and element_data
--
--

-- -----------------------------------------------------------------------------
-- Sequences

-- Unique IDs for the element table
CREATE SEQUENCE seq_element START 1024;

-- Unique IDs for element__output_channel
CREATE SEQUENCE seq_element__output_channel START 1024;

-- Unique IDs for element__input_channel
CREATE SEQUENCE seq_element__input_channel START 1024;

-- Unique IDs for element__language
--CREATE SEQUENCE seq_element__language START 1024;

-- Unique IDs for element_member
CREATE SEQUENCE seq_element_member START 1024;

-- Unique IDs for the attr_element table
CREATE SEQUENCE seq_attr_element START 1024;

-- Unique IDs for each attr_element_*_val table
CREATE SEQUENCE seq_attr_element_val START 1024;

-- Unique IDs for the element_meta table
CREATE SEQUENCE seq_attr_element_meta START 1024;

-- Unique IDs for the element__site table.
CREATE SEQUENCE seq_element__site START 1024;

-- -----------------------------------------------------------------------------
-- Table: element
--
-- Description: The table that holds the information for a given asset type.  
--              Holds name and description information and is references by 
--              element_contaner and element_data rows.
--

CREATE TABLE element  (
    id              INTEGER        NOT NULL
                                   DEFAULT NEXTVAL('seq_element'),
    name            VARCHAR(64)    NOT NULL,
    key_name        VARCHAR(64)    NOT NULL,
    description     VARCHAR(256),
    burner          INT2           NOT NULL DEFAULT 1,
    reference       BOOLEAN        NOT NULL DEFAULT FALSE,
    type__id        INTEGER        NOT NULL,
    at_grp__id      INTEGER,
    active          BOOLEAN        NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_element__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table: element__site
--
-- Description: A table that maps 

CREATE TABLE element__site (
    id              INTEGER        NOT NULL
                                   DEFAULT NEXTVAL('seq_element__site'),
    element__id    INTEGER         NOT NULL,
    site__id       INTEGER         NOT NULL,
    active         BOOLEAN         NOT NULL DEFAULT TRUE,
    primary_oc__id  INTEGER        NOT NULL,
    CONSTRAINT pk_element__site__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table: element__output_channel
--
-- Description: Holds a reference to the asset type table, the output channel 
--              table and an active flag
--

CREATE TABLE element__output_channel (
    id                  INTEGER    NOT NULL
                                   DEFAULT NEXTVAL('seq_element__output_channel'),
    element__id         INTEGER    NOT NULL,
    output_channel__id  INTEGER    NOT NULL,
    enabled             BOOLEAN    NOT NULL DEFAULT TRUE,
    active              BOOLEAN    NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_at__oc__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table: element__input_channel
--
-- Description: Holds a reference to the asset type table, the input channel 
--              table and an active flag
--

CREATE TABLE element__input_channel (
    id                  INTEGER    NOT NULL
                                   DEFAULT NEXTVAL('seq_element__input_channel'),
    element__id         INTEGER    NOT NULL,
    input_channel__id   INTEGER    NOT NULL,
    enabled             BOOLEAN    NOT NULL DEFAULT TRUE,
    active              BOOLEAN    NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_at__ic__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table: element__language
--
-- Description: Holds a reference to the asset type table, the language 
--              table and an active flag
--

/*

CREATE TABLE element__language (
    id               INTEGER  NOT NULL
                              DEFAULT NEXTVAL('seq_element__language'),
    element__id      INTEGER  NOT NULL,
    language__id     INTEGER  NOT NULL,
    active           BOOLEAN  NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_element__language__id PRIMARY KEY (id)
);

*/

-- -----------------------------------------------------------------------------
-- Table: element_member
-- 
-- Description: The link between element objects and member objects
--

CREATE TABLE element_member (
    id          INTEGER  NOT NULL
                         DEFAULT NEXTVAL('seq_element_member'),
    object_id   INTEGER  NOT NULL,
    member__id  INTEGER  NOT NULL,
    CONSTRAINT pk_element_member__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table: attr_element
--
-- Description: A table to represent types of attributes.  A type is defined by
--              its subsystem, its element ID and an attribute name.

CREATE TABLE attr_element (
    id         INTEGER       NOT NULL
                             DEFAULT NEXTVAL('seq_attr_element'),
    subsys     VARCHAR(256)  NOT NULL,
    name       VARCHAR(256)  NOT NULL,
    sql_type   VARCHAR(30)   NOT NULL,
    active     BOOLEAN       NOT NULL DEFAULT TRUE,
   CONSTRAINT pk_attr_element__id PRIMARY KEY (id)
);


-- -----------------------------------------------------------------------------
-- Table: attr_element_val
--
-- Description: A table to hold attribute values.

CREATE TABLE attr_element_val (
    id           INTEGER      NOT NULL
                              DEFAULT NEXTVAL('seq_attr_element_val'),
    object__id   INTEGER      NOT NULL,
    attr__id     INTEGER      NOT NULL,
    date_val     TIMESTAMP,
    short_val    VARCHAR(1024),
    blob_val     TEXT,
    serial       BOOLEAN      DEFAULT FALSE,
    active       BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_attr_element_val__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table: attr_element_meta
--
-- Description: A table to represent metadata on types of attributes.

CREATE TABLE attr_element_meta (
    id        INTEGER         NOT NULL
                              DEFAULT NEXTVAL('seq_attr_element_meta'),
    attr__id  INTEGER         NOT NULL,
    name      VARCHAR(256)    NOT NULL,
    value     VARCHAR(2048),
    active    BOOLEAN         NOT NULL DEFAULT TRUE,
   CONSTRAINT pk_attr_element_meta__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Indexes.
--
CREATE UNIQUE INDEX udx_element__key_name ON element(LOWER(key_name));
CREATE INDEX fkx_at_type__element ON element(type__id);
CREATE INDEX fkx_grp__element ON element(at_grp__id);


CREATE UNIQUE INDEX udx_at_oc_id__at__oc_id ON element__output_channel(element__id, output_channel__id);
CREATE INDEX fkx_output_channel__at_oc ON element__output_channel(output_channel__id);
CREATE INDEX fkx_element__at_oc ON element__output_channel(element__id);

CREATE UNIQUE INDEX udx_at_ic_id__at__ic_id ON element__input_channel(element__id, input_channel__id);
CREATE INDEX fkx_input_channel__at_ic ON element__input_channel(input_channel__id);
CREATE INDEX fkx_element__at_ic ON element__input_channel(element__id);

--CREATE UNIQUE INDEX udx_at_language__at_id__lang_id ON element__language(element__id,language__id);

CREATE INDEX fkx_element__at_member ON element_member(object_id);
CREATE INDEX fkx_member__at_member ON element_member(member__id);

CREATE UNIQUE INDEX udx_element__site on element__site(element__id, site__id);


-- Unique index on subsystem/name pair
CREATE UNIQUE INDEX udx_attr_at__subsys__name ON attr_element(subsys, name);

-- Indexes on name and subsys.
CREATE INDEX idx_attr_at__name ON attr_element(LOWER(name));
CREATE INDEX idx_attr_at__subsys ON attr_element(LOWER(subsys));

-- Unique index on object__id/attr__id pair
CREATE UNIQUE INDEX udx_attr_at_val__obj_attr ON attr_element_val (object__id,attr__id);

-- FK indexes on object__id and attr__id.
CREATE INDEX fkx_at__attr_at_val ON attr_element_val(object__id);
CREATE INDEX fkx_attr_at__attr_at_val ON attr_element_val(attr__id);

-- Unique index on attr__id/name pair
CREATE UNIQUE INDEX udx_attr_at_meta__attr_name ON attr_element_meta (attr__id, name);

-- Index on meta name.
CREATE INDEX idx_attr_at_meta__name ON attr_element_meta(LOWER(name));

-- FK index on attr__id.
CREATE INDEX fkx_attr_at__attr_at_meta ON attr_element_meta(attr__id);

-- FK index on element__site.
CREATE INDEX fkx_element__element__site__element__id ON element__site(element__id);
CREATE INDEX fkx_site__element__site__site__id ON element__site(site__id);
CREATE INDEX fkx_output_channel__element__site ON element__site(primary_oc__id);



