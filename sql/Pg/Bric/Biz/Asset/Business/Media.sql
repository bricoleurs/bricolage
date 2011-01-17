-- Project: Bricolage
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Michael Soderstrom <miraso@pacbell.net>
--
-- The sql representation of Media Assets.

-- -----------------------------------------------------------------------------
-- Sequences

-- Unique IDs for the media table
CREATE SEQUENCE seq_media START 1024;

CREATE SEQUENCE seq_media_instance START 1024;

-- Unique ids for the media__contributor table
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
    element_type__id  INTEGER   NOT NULL,
    current_version   INTEGER,
    published_version INTEGER,
    usr__id           INTEGER,
    first_publish_date TIMESTAMP,
    publish_date      TIMESTAMP,
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
    name                VARCHAR(256),
    description         VARCHAR(1024),
    media__id           INTEGER   NOT NULL,
    source__id          INTEGER   NOT NULL,
    priority            INT2      NOT NULL
                                  DEFAULT 3
                                  CONSTRAINT ck_media__priority
                                  CHECK (priority BETWEEN 1 AND 5),
    usr__id             INTEGER   NOT NULL,
    version             INTEGER,
    expire_date         TIMESTAMP,
    category__id        INTEGER   NOT NULL,
    media_type__id      INTEGER   NOT NULL,
    primary_oc__id      INTEGER   NOT NULL,
    file_size           INTEGER,
    file_name           VARCHAR(256),
    location            VARCHAR(256),
    uri                 VARCHAR(256),
    cover_date          TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    note                TEXT,
    checked_out         BOOLEAN    NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_media_instance__id PRIMARY KEY (id)
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
    media_instance__id  INTEGER  NOT NULL,
    output_channel__id  INTEGER  NOT NULL,
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
    media_instance__id  INTEGER   NOT NULL,
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
CREATE INDEX idx_media_instance__cover_date ON media_instance(cover_date);
CREATE INDEX fkx_usr__media ON media(usr__id);
CREATE INDEX fkx_element_type__media ON media(element_type__id);
CREATE INDEX fkx_site_id__media ON media(site__id);
CREATE INDEX fkx_alias_id__media ON media(alias_id);

-- media_instance
CREATE INDEX idx_media_instance__name ON media_instance(LOWER(name));
CREATE INDEX idx_media_instance__description ON media_instance(LOWER(description));
CREATE INDEX fkx_media_instance__source ON media_instance(source__id);
CREATE INDEX idx_media_instance__file_name ON media_instance(LOWER(file_name));
CREATE INDEX idx_media_instance__uri ON media_instance(LOWER(uri));
CREATE UNIQUE INDEX udx_media__media_instance ON media_instance(media__id, version, checked_out);
CREATE INDEX fkx_usr__media_instance ON media_instance(usr__id);
CREATE INDEX fkx_media_type__media_instance ON media_instance(media_type__id);
CREATE INDEX fkx_category__media_instance ON media_instance(category__id);
CREATE INDEX fkx_primary_oc__media_instance ON media_instance(primary_oc__id);
CREATE INDEX idx_media_instance__note ON media_instance(note) WHERE note IS NOT NULL;

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

CREATE INDEX fkx_media__desk__id ON media(desk__id) WHERE desk__id > 0;
CREATE INDEX fkx_media__workflow__id ON media(workflow__id) WHERE workflow__id > 0;
