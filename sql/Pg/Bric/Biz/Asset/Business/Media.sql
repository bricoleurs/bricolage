-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate$
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Michael Soderstrom <miraso@pacbell.net>
--
-- The sql representation of Media Assets.

-- -----------------------------------------------------------------------------
-- Sequences

-- Unique IDs for the media table
CREATE SEQUENCE seq_media START 1024;

CREATE SEQUENCE seq_media_instance START 1024;

-- Unique ids for the media_contributor table
CREATE SEQUENCE seq_media__contributor START 1024;

-- Unique IDs for the media_member table
CREATE SEQUENCE seq_media_member START 1024;

CREATE SEQUENCE seq_media_fields START 1024;

-- Unique IDs for the attr_media table
CREATE SEQUENCE seq_attr_media START  1024;

-- Unique IDs for each attr_media_*_val table
CREATE SEQUENCE seq_attr_media_val START 1024;

-- Unique IDs for the media_meta table
CREATE SEQUENCE seq_attr_media_meta START 1024;

-- Unique IDs for the media_uri table
CREATE SEQUENCE seq_media_uri START 1024;


-- -----------------------------------------------------------------------------
-- Table media
-- 
-- Description: The Media table this houses the data for a given media asset
--                              and its related asset_version_data
--

CREATE TABLE media (
    id                NUMERIC(10,0)   NOT NULL
                                      DEFAULT NEXTVAL('seq_media'),
    element__id       NUMERIC(10,0)   NOT NULL,
    priority          NUMERIC(1,0)    NOT NULL
                                      DEFAULT 3
                                      CONSTRAINT ck_media__priority
                                        CHECK (priority BETWEEN 1 AND 5),
    source__id        NUMERIC(10,0)   NOT NULL,
    current_version   NUMERIC(10,0),
    published_version NUMERIC(10,0),
    usr__id           NUMERIC(10,0),
    first_publish_date TIMESTAMP,
    publish_date      TIMESTAMP,
    expire_date       TIMESTAMP,
    cover_date        TIMESTAMP,
    workflow__id      NUMERIC(10,0)   NOT NULL,
    desk__id          NUMERIC(10,0)   NOT NULL,
    publish_status    NUMERIC(1,0)    NOT NULL
                                      DEFAULT 0
                                      CONSTRAINT ck_media__publish_status 
                                        CHECK (publish_status IN (0,1)),
    active            NUMERIC(1,0)    NOT NULL
                                      DEFAULT 1
                                      CONSTRAINT ck_media__active
                                        CHECK (active IN (0,1)),
    site__id          NUMERIC(10,0)   NOT NULL,
    alias_id          NUMERIC(10,0)   CONSTRAINT ck_media_id
                                        CHECK (alias_id != id),  
    CONSTRAINT pk_media__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table: media_instance
--
-- Description: An instance of a media object
--
--

CREATE TABLE media_instance (
    id                  NUMERIC(10,0)   NOT NULL
                                        DEFAULT NEXTVAL('seq_media_instance'),
    name                VARCHAR(256),
    description         VARCHAR(1024),
    media__id           NUMERIC(10,0)   NOT NULL,
    usr__id             NUMERIC(10,0)   NOT NULL,
    version             NUMERIC(10,0),
    category__id        NUMERIC(10,0)   NOT NULL,
    media_type__id      NUMERIC(10,0)   NOT NULL,
    primary_oc__id      NUMERIC(10,0)   NOT NULL,
    file_size           NUMERIC(10,0),
    file_name           VARCHAR(256),
    location            VARCHAR(256),
    uri                 VARCHAR(256),
    checked_out         NUMERIC(1,0)    NOT NULL
                                        DEFAULT 0
                                        CONSTRAINT ck_media_instance__checked_out 
                                        CHECK (checked_out IN(0,1)),
    CONSTRAINT pk_media_instance__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table media_uri
--
-- Description: Tracks all URIs for stories.
--
CREATE TABLE media_uri (
    id        NUMERIC(10,0)   NOT NULL
                              DEFAULT NEXTVAL('seq_media_uri'),
    media__id NUMERIC(10)     NOT NULL,
    site__id  NUMERIC(10)     NOT NULL,
    uri       TEXT            NOT NULL,
    CONSTRAINT pk_media_uri__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table media__output_channel
-- 
-- Description: Mapping Table between stories and output channels.
--
--

CREATE TABLE media__output_channel (
    media_instance__id  NUMERIC(10, 0)  NOT NULL,
    output_channel__id  NUMERIC(10, 0)  NOT NULL,
    CONSTRAINT pk_media_output_channel
      PRIMARY KEY (media_instance__id, output_channel__id)
);

-- -----------------------------------------------------------------------------
-- Table: media_fields
-- 
-- Description: A mapping table between Media classes and functions that
--                              Will be run against uploaded files
-- 
CREATE TABLE media_fields (
    id              NUMERIC(10,0)  NOT NULL     
                                   DEFAULT NEXTVAL('seq_media_fields'),
    biz_pkg         NUMERIC(10,0)  NOT NULL,
    name            VARCHAR(32)    NOT NULL,
    function_name   VARCHAR(256)   NOT NULL,
    active          NUMERIC(1,0)   NOT NULL
                                   DEFAULT 1
                                   CONSTRAINT ck_media_fields__active
                                     CHECK (active IN(0,1)) ,
    CONSTRAINT pk_media_fields__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table media__contributor
-- 
-- Description: mapping tables between media instances and contributors
--
--

CREATE TABLE media__contributor (
    id                  NUMERIC(10,0)   NOT NULL
                                        DEFAULT NEXTVAL('seq_media__contributor'),
    media_instance__id  NUMERIC(10,0)   NOT NULL,
    member__id          NUMERIC(10,0)   NOT NULL,
    place               NUMERIC(3,0)    NOT NULL,
    role                VARCHAR(256),
    CONSTRAINT pk_media_category_id PRIMARY KEY (id)
);


-- -----------------------------------------------------------------------------
-- Table: media_member
-- 
-- Description: The link between media objects and member objects
--

CREATE TABLE media_member (
    id          NUMERIC(10,0)  NOT NULL
                               DEFAULT NEXTVAL('seq_media_member'),
    object_id   NUMERIC(10,0)  NOT NULL,
    member__id  NUMERIC(10,0)  NOT NULL,
    CONSTRAINT pk_media_member__id PRIMARY KEY (id)
);


-- Table: attr_media
--
-- Description: A table to represent types of attributes.  A type is defined by
--              its subsystem, its media ID and an attribute name.

CREATE TABLE attr_media (
    id         NUMERIC(10)   NOT NULL
                             DEFAULT NEXTVAL('seq_attr_media'),
    subsys     VARCHAR(256)  NOT NULL,
    name       VARCHAR(256)  NOT NULL,
    sql_type   VARCHAR(30)   NOT NULL,
    active     NUMERIC(1)    DEFAULT 1
                             NOT NULL
                             CONSTRAINT ck_attr_media__active CHECK (active IN (0,1)),
   CONSTRAINT pk_attr_media__id PRIMARY KEY (id)
);


-- ------------------------------------------------------------------------------- Table: attr_media_val
--
-- Description: A table to hold attribute values.

CREATE TABLE attr_media_val (
    id           NUMERIC(10)     NOT NULL
                                 DEFAULT NEXTVAL('seq_attr_media_val'),
    object__id   NUMERIC(10)     NOT NULL,
    attr__id     NUMERIC(10)     NOT NULL,
    date_val     TIMESTAMP,
    short_val    VARCHAR(1024),
    blob_val     TEXT,
    serial       NUMERIC(1)      DEFAULT 0,
    active       NUMERIC(1)      DEFAULT 1
                                 NOT NULL
                                 CONSTRAINT ck_attr_media_val__active CHECK (active IN (0,1)),
    CONSTRAINT pk_attr_media_val__id PRIMARY KEY (id)
);


-- ------------------------------------------------------------------------------- Table: attr_media_meta
--
-- Description: A table to represent metadata on types of attributes.

CREATE TABLE attr_media_meta (
    id        NUMERIC(10)     NOT NULL
                              DEFAULT NEXTVAL('seq_attr_media_meta'),
    attr__id  NUMERIC(10)     NOT NULL,
    name      VARCHAR(256)    NOT NULL,
    value     VARCHAR(2048),
    active    NUMERIC(1)      DEFAULT 1
                              NOT NULL
                              CONSTRAINT ck_attr_media_meta__active CHECK (active IN (0,1)),
   CONSTRAINT pk_attr_media_meta__id PRIMARY KEY (id)
);



--
-- INDEXES.
--

-- media
CREATE INDEX idx_media__first_publish_date ON media(first_publish_date);
CREATE INDEX idx_media__publish_date ON media(publish_date);
CREATE INDEX idx_media__cover_date ON media(cover_date);
CREATE INDEX fkx_source__media ON media(source__id);
CREATE INDEX fkx_usr__media ON media(usr__id);
CREATE INDEX fkx_element__media ON media(element__id);
CREATE INDEX fkx_site_id__media ON media(site__id);
CREATE INDEX fdx_alias_id__media ON media(alias_id);

-- media_instance
CREATE INDEX idx_media_instance__name ON media_instance(LOWER(name));
CREATE INDEX idx_media_instance__description ON media_instance(LOWER(description));
CREATE INDEX idx_media_instance__file_name ON media_instance(LOWER(file_name));
CREATE INDEX idx_media_instance__uri ON media_instance(LOWER(uri));
CREATE INDEX fkx_media__media_instance ON media_instance(media__id);
CREATE INDEX fkx_usr__media_instance ON media_instance(usr__id);
CREATE INDEX fkx_media_type__media_instance ON media_instance(media_type__id);
CREATE INDEX fkx_category__media_instance ON media_instance(category__id);
CREATE INDEX fdx_primary_oc__media_instance ON media_instance(primary_oc__id);

-- media_uri
CREATE INDEX fkx_media__media_uri ON media_uri(media__id);
CREATE UNIQUE INDEX udx_media_uri__site_id__uri
ON media_uri(lower_text_num(uri, site__id));

-- media__output_channel
CREATE INDEX fkx_media__oc__media ON media__output_channel(media_instance__id);
CREATE INDEX fkx_media__oc__oc ON media__output_channel(output_channel__id);

--media__contributor
CREATE INDEX fkx_media__media__contributor ON media__contributor(media_instance__id);
CREATE INDEX fkx_member__media__contributor ON media__contributor(member__id);

-- media_member.
CREATE INDEX fkx_media__media_member ON media_member(object_id);
CREATE INDEX fkx_member__media_member ON media_member(member__id);

-- Unique index on subsystem/name pair
CREATE UNIQUE INDEX udx_attr_media__subsys__name ON attr_media(subsys, name);

-- Indexes on name and subsys.
CREATE INDEX idx_attr_media__name ON attr_media(LOWER(name));
CREATE INDEX idx_attr_media__subsys ON attr_media(LOWER(subsys));

-- Unique index on object__id/attr__id pair
CREATE UNIQUE INDEX udx_attr_media_val__obj_attr ON attr_media_val (object__id,attr__id);

-- FK indexes on object__id and attr__id.
CREATE INDEX fkx_media__attr_media_val ON attr_media_val(object__id);
CREATE INDEX fkx_attr_media__attr_media_val ON attr_media_val(attr__id);

-- Unique index on attr__id/name pair
CREATE UNIQUE INDEX udx_attr_media_meta__attr_name ON attr_media_meta (attr__id, name);

-- Index on meta name.
CREATE INDEX idx_attr_media_meta__name ON attr_media_meta(LOWER(name));

-- FK index on attr__id.
CREATE INDEX fkx_attr_media__attr_media_meta ON attr_media_meta(attr__id);

CREATE INDEX fdx_media__desk__id ON media(desk__id) WHERE desk__id > 0;
CREATE INDEX fdx_media__workflow__id ON media(workflow__id) WHERE workflow__id > 0;
