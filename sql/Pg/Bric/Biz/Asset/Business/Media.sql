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

CREATE SEQUENCE seq_media_version START 1024;

-- Unique ids for the media_contributor table
CREATE SEQUENCE seq_media__contributor START 1024;

-- Unique IDs for the media_member table
CREATE SEQUENCE seq_media_member START 1024;

CREATE SEQUENCE seq_media_fields START 1024;

-- Unique IDs for the media_uri table
CREATE SEQUENCE seq_media_uri START 1024;


-- -----------------------------------------------------------------------------
-- Table media
-- 
-- Description: The Media table this houses the data for a given media asset
--                              and its related asset_version_data
--

CREATE TABLE media (
    id                INTEGER   NOT NULL
                                      DEFAULT NEXTVAL('seq_media'),
    uuid              TEXT            NOT NULL,
    element__id       INTEGER   NOT NULL,
    priority          INT2      NOT NULL
                                      DEFAULT 3
                                      CONSTRAINT ck_media__priority
                                        CHECK (priority BETWEEN 1 AND 5),
    source__id        INTEGER   NOT NULL,
    current_version   INTEGER,
    published_version INTEGER,
    usr__id           INTEGER,
    first_publish_date TIMESTAMP,
    publish_date      TIMESTAMP,
    expire_date       TIMESTAMP,
    cover_date        TIMESTAMP,
    workflow__id      INTEGER   NOT NULL,
    desk__id          INTEGER   NOT NULL,
    publish_status    BOOLEAN    NOT NULL DEFAULT FALSE,
    active            BOOLEAN    NOT NULL DEFAULT TRUE,
    site__id          INTEGER   NOT NULL,
    alias_id          INTEGER   CONSTRAINT ck_media_id
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
    id                  INTEGER   NOT NULL
                                        DEFAULT NEXTVAL('seq_media_instance'),
    input_channel__id   INTEGER  NOT NULL,
    name                VARCHAR(256),
    description         VARCHAR(1024),
    file_size           INTEGER,
    file_name           VARCHAR(256),
    location            VARCHAR(256),
    uri                 VARCHAR(256),
    CONSTRAINT pk_media_instance__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table: media_version
--
-- Description: An version of a media object
--
--

CREATE TABLE media_version (
    id                  INTEGER   NOT NULL
                                        DEFAULT NEXTVAL('seq_media_version'),
    media__id           INTEGER   NOT NULL,
    version             INTEGER,
    usr__id             INTEGER   NOT NULL,
    category__id        INTEGER   NOT NULL,
    media_type__id      INTEGER   NOT NULL,
    primary_oc__id      INTEGER   NOT NULL,
    primary_ic__id      INTEGER   NOT NULL,
    note                TEXT,
    checked_out         BOOLEAN    NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_media_version__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table media_uri
--
-- Description: Tracks all URIs for stories.
--
CREATE TABLE media_uri (
    id        INTEGER     NOT NULL
                              DEFAULT NEXTVAL('seq_media_uri'),
    media__id INTEGER     NOT NULL,
    site__id  INTEGER     NOT NULL,
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
    media_version__id  INTEGER  NOT NULL,
    output_channel__id  INTEGER  NOT NULL,
    CONSTRAINT pk_media_output_channel
      PRIMARY KEY (media_version__id, output_channel__id)
);

-- -----------------------------------------------------------------------------
-- Table media_instance__media_version
-- 
-- Description: Mapping Table between media versions and media instances
--
--

CREATE TABLE media_instance__media_version (
    media_instance__id  INTEGER  NOT NULL,
    media_version__id   INTEGER  NOT NULL,
    CONSTRAINT pk_media_instance__media_version
      PRIMARY KEY (media_instance__id, media_version__id)
);

-- -----------------------------------------------------------------------------
-- Table: media_fields
-- 
-- Description: A mapping table between Media classes and functions that
--                              Will be run against uploaded files
-- 
CREATE TABLE media_fields (
    id              INTEGER  NOT NULL     
                                   DEFAULT NEXTVAL('seq_media_fields'),
    biz_pkg         INTEGER  NOT NULL,
    name            VARCHAR(32)    NOT NULL,
    function_name   VARCHAR(256)   NOT NULL,
    active          BOOLEAN   NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_media_fields__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table media__contributor
-- 
-- Description: mapping tables between media instances and contributors
--
--

CREATE TABLE media__contributor (
    id                  INTEGER   NOT NULL
                                        DEFAULT NEXTVAL('seq_media__contributor'),
    media_version__id   INTEGER   NOT NULL,
    member__id          INTEGER   NOT NULL,
    place               INT2      NOT NULL,
    role                VARCHAR(256),
    CONSTRAINT pk_media_category_id PRIMARY KEY (id)
);


-- -----------------------------------------------------------------------------
-- Table: media_member
-- 
-- Description: The link between media objects and member objects
--

CREATE TABLE media_member (
    id          INTEGER  NOT NULL
                               DEFAULT NEXTVAL('seq_media_member'),
    object_id   INTEGER  NOT NULL,
    member__id  INTEGER  NOT NULL,
    CONSTRAINT pk_media_member__id PRIMARY KEY (id)
);


--
-- INDEXES.
--

-- media
CREATE INDEX idx_media__uuid ON media(uuid);
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

-- media_version
CREATE INDEX fkx_media__media_version ON media_version(media__id);
CREATE INDEX fdx_primary_oc__media_version ON media_version(primary_oc__id);
CREATE INDEX fdx_primary_ic__media_version ON media_version(primary_ic__id);
CREATE INDEX fkx_usr__media_version ON media_version(usr__id);
CREATE INDEX fkx_media_type__media_version ON media_version(media_type__id);
CREATE INDEX fkx_category__media_version ON media_version(category__id);
CREATE INDEX idx_media_version__note ON media_version(note) WHERE note IS NOT NULL;

-- media_uri
CREATE INDEX fkx_media__media_uri ON media_uri(media__id);
CREATE UNIQUE INDEX udx_media_uri__site_id__uri
ON media_uri(lower_text_num(uri, site__id));

-- media__output_channel
CREATE INDEX fkx_media__oc__media ON media__output_channel(media_version__id);
CREATE INDEX fkx_media__oc__oc ON media__output_channel(output_channel__id);

-- media_instance__media_version
CREATE INDEX fkx_media_inst__vers__inst ON media_instance__media_version (media_instance__id);
CREATE INDEX fkx_media_inst__vers__vers ON media_instance__media_version (media_version__id);

-- media_member.
CREATE INDEX fkx_media__media_member ON media_member(object_id);
CREATE INDEX fkx_member__media_member ON media_member(member__id);

CREATE INDEX fdx_media__desk__id ON media(desk__id) WHERE desk__id > 0;
CREATE INDEX fdx_media__workflow__id ON media(workflow__id) WHERE workflow__id > 0;
