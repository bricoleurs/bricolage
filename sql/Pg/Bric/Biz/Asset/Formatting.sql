-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate$
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Michael Soderstrom <miraso@pacbell.net>
--
-- The sql that will hold all the formatting asset information.
-- This replaces the Data, Container, Decorative Tables which 
-- were archectited away.

-- -----------------------------------------------------------------------------
-- Sequences

-- Unique ids for the formatting table
CREATE SEQUENCE seq_formatting START 1024;

CREATE SEQUENCE seq_formatting_instance START 1024;

CREATE SEQUENCE seq_formatting_version START 1024;

-- Unique IDs for the story_member table
CREATE SEQUENCE seq_formatting_member START 1024;

-- Unique IDs for the attr_formatting table
CREATE SEQUENCE seq_attr_formatting START 1024;

-- Unique IDs for each attr_formatting_*_val table
CREATE SEQUENCE seq_attr_formatting_val START 1024;

-- Unique IDs for the formatting_meta table
CREATE SEQUENCE seq_attr_formatting_meta START 1024;


-- -----------------------------------------------------------------------------
-- Table formatting
--
-- Description: The table that holds all the formatting info
--
--
CREATE TABLE formatting (
    id                  INTEGER        NOT NULL
                                       DEFAULT NEXTVAL('seq_formatting'),
    name                VARCHAR(256),
    description         VARCHAR(1024),
    priority            INT2           NOT NULL
                                       DEFAULT 3
                                       CONSTRAINT ck_story__priority
                                         CHECK (priority BETWEEN 1 AND 5),
    usr__id             INTEGER,  
    output_channel__id  INTEGER        NOT NULL,
    tplate_type         INT2           NOT NULL
                                       DEFAULT 1
                                       CONSTRAINT ck_formatting___tplate_type
                                         CHECK (tplate_type IN (1, 2, 3)),
    element__id         INTEGER,
    category__id        INTEGER,
    file_name           TEXT,
    current_version     INTEGER        NOT NULL,
    workflow__id        INTEGER        NOT NULL,
    desk__id            INTEGER        NOT NULL,
    published_version   INTEGER,
    deploy_status       BOOLEAN        NOT NULL DEFAULT FALSE,
    deploy_date         TIMESTAMP,
    expire_date         TIMESTAMP,
    active              BOOLEAN        NOT NULL DEFAULT TRUE,
    site__id            INTEGER        NOT NULL,
    CONSTRAINT pk_formatting__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table formatting_instance
--
-- Description:  An versioned instance of a formatting asset
--

CREATE TABLE formatting_instance (
    id              INTEGER        NOT NULL
                                       DEFAULT NEXTVAL('seq_formatting_instance'),
    formatting_version__id  INTEGER        NOT NULL,
    usr__id         INTEGER        NOT NULL,
    file_name       TEXT,
    data            TEXT,
    CONSTRAINT pk_formatting_instance__id PRIMARY KEY (id)
);


-- -----------------------------------------------------------------------------
-- Table formatting_version
--
-- Description:  An version of a formatting asset
--

CREATE TABLE formatting_version (
    id              INTEGER        NOT NULL
                                       DEFAULT NEXTVAL('seq_formatting_version'),
    formatting__id  INTEGER        NOT NULL,
    version         INTEGER,
    checked_out     BOOLEAN        NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_formatting_version__id PRIMARY KEY (id)
);
        

-- -----------------------------------------------------------------------------
-- Table: formatting_member
-- 
-- Description: The link between element objects and member objects
--

CREATE TABLE formatting_member (
    id          INTEGER        NOT NULL
                               DEFAULT NEXTVAL('seq_formatting_member'),
    object_id   INTEGER        NOT NULL,
    member__id  INTEGER        NOT NULL,
    CONSTRAINT pk_formatting_member__id PRIMARY KEY (id)
);

-- -------------------------------------------------------------------------------
-- Table: attr_formatting
--
-- Description: A table to represent types of attributes.  A type is defined by
--              its subsystem, its formatting ID and an attribute name.

CREATE TABLE attr_formatting (
    id         INTEGER       NOT NULL
                             DEFAULT NEXTVAL('seq_attr_formatting'),
    subsys     VARCHAR(256)  NOT NULL,
    name       VARCHAR(256)  NOT NULL,
    sql_type   VARCHAR(30)   NOT NULL,
    active     BOOLEAN       NOT NULL DEFAULT TRUE,
   CONSTRAINT pk_attr_formatting__id PRIMARY KEY (id)
);


-- -------------------------------------------------------------------------------
-- Table: attr_formatting_val
--
-- Description: A table to hold attribute values.

CREATE TABLE attr_formatting_val (
    id           INTEGER         NOT NULL
                                 DEFAULT NEXTVAL('seq_attr_formatting_val'),
    object__id   INTEGER         NOT NULL,
    attr__id     INTEGER         NOT NULL,
    date_val     TIMESTAMP,
    short_val    VARCHAR(1024),
    blob_val     TEXT,
    serial       BOOLEAN         DEFAULT FALSE,
    active       BOOLEAN         NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_attr_formatting_val__id PRIMARY KEY (id)
);


-- -------------------------------------------------------------------------------
-- Table: attr_formatting_meta
--
-- Description: A table to represent metadata on types of attributes.

CREATE TABLE attr_formatting_meta (
    id        INTEGER         NOT NULL
                              DEFAULT NEXTVAL('seq_attr_formatting_meta'),
    attr__id  INTEGER         NOT NULL,
    name      VARCHAR(256)    NOT NULL,
    value     VARCHAR(2048),
    active    BOOLEAN         NOT NULL DEFAULT TRUE,
   CONSTRAINT pk_attr_formatting_meta__id PRIMARY KEY (id)
);


-- -----------------------------------------------------------------------------
-- Indexes.
--

-- formatting.
CREATE UNIQUE INDEX udx_formatting__file_name__oc
       ON formatting(file_name, output_channel__id);
CREATE INDEX idx_formatting__name ON formatting(LOWER(name));
CREATE INDEX idx_formatting__file_name ON formatting(LOWER(file_name));
CREATE INDEX idx_formatting__description ON formatting(LOWER(description));
CREATE INDEX idx_formatting__deploy_date ON formatting(deploy_date);
CREATE INDEX fkx_usr__formatting ON formatting(usr__id);
CREATE INDEX fkx_output_channel__formatting ON formatting(output_channel__id);
CREATE INDEX fkx_element__formatting ON formatting(element__id);
CREATE INDEX fkx_category__formatting ON formatting(category__id);
CREATE INDEX fdx_formatting__desk__id ON formatting(desk__id) WHERE desk__id > 0;
CREATE INDEX fdx_formatting__workflow__id ON formatting(workflow__id) WHERE workflow__id > 0;
CREATE INDEX fkx_site__formatting ON formatting(site__id);

-- formatting_instance.
CREATE INDEX fkx_usr__formatting_instance ON formatting_instance(usr__id);
CREATE INDEX fkx_frmt_version__frmt_instance ON formatting_instance(formatting_version__id);

-- formatting_version
CREATE INDEX fkx_formatting__frmt_version ON formatting_version(formatting__id);

-- formatting_member.
CREATE INDEX fkx_frmt__frmt_member ON formatting_member(object_id);
CREATE INDEX fkx_member__frmt_member ON formatting_member(member__id);

-- Unique index on subsystem/name pair.
CREATE UNIQUE INDEX udx_attr_frmt__subsys__name ON attr_formatting(subsys, name);

-- Indexes on name and subsys.
CREATE INDEX idx_attr_frmt__name ON attr_formatting(LOWER(name));
CREATE INDEX idx_attr_frmt__subsys ON attr_formatting(LOWER(subsys));

-- Unique index on object__id/attr__id pair.
CREATE UNIQUE INDEX udx_attr_frmt_val__obj_attr ON attr_formatting_val (object__id,attr__id);

-- FK indexes on object__id and attr__id.
CREATE INDEX fkx_frmt__attr_frmt_val ON attr_formatting_val(object__id);
CREATE INDEX fkx_attr_frmt__attr_frmt_val ON attr_formatting_val(attr__id);

-- Unique index on attr__id/name pair.
CREATE UNIQUE INDEX udx_attr_frmt_meta__attr_name ON attr_formatting_meta (attr__id, name);

-- Index on meta name.
CREATE INDEX idx_attr_frmt_meta__name ON attr_formatting_meta(LOWER(name));

-- FK index on attr__id.
CREATE INDEX fkx_attr_frmt__attr_frmt_meta ON attr_formatting_meta(attr__id);
