-- Project: Bricolage
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Michael Soderstrom <miraso@pacbell.net>
--
-- The sql representation of Media Assets.

-- -----------------------------------------------------------------------------
-- Table media
-- 
-- Description: The Media table this houses the data for a given media asset
--                              and its related asset_version_data
--

CREATE TABLE media (
    id                INTEGER    NOT NULL AUTO_INCREMENT,
    uuid              TEXT            NOT NULL,
    element_type__id  INTEGER    NOT NULL,
    priority          INT2       NOT NULL
                                      DEFAULT 3
                                        CHECK (priority BETWEEN 1 AND 5),
    source__id        INTEGER    NOT NULL,
    current_version   INTEGER,
    published_version INTEGER,
    usr__id           INTEGER,
    first_publish_date TIMESTAMP NULL DEFAULT NULL,
    publish_date      TIMESTAMP  NULL DEFAULT NULL,
    expire_date       TIMESTAMP  NULL DEFAULT NULL,
    workflow__id      INTEGER    NOT NULL,
    desk__id          INTEGER    NOT NULL,
    publish_status    BOOLEAN    NOT NULL DEFAULT FALSE,
    active            BOOLEAN    NOT NULL DEFAULT TRUE,
    site__id          INTEGER    NOT NULL,
    alias_id          INTEGER   
                                        CHECK (alias_id != id),  
    CONSTRAINT pk_media__id PRIMARY KEY (id)
)
    ENGINE            InnoDB
    AUTO_INCREMENT    1024;

-- -----------------------------------------------------------------------------
-- Table: media_instance
--
-- Description: An instance of a media object
--
--

CREATE TABLE media_instance (
    id                  INTEGER   NOT NULL AUTO_INCREMENT,
    name                VARCHAR(256),
    description         VARCHAR(1024),
    media__id           INTEGER   NOT NULL,
    usr__id             INTEGER   NOT NULL,
    version             INTEGER,
    category__id        INTEGER   NOT NULL,
    media_type__id      INTEGER   NOT NULL,
    primary_oc__id      INTEGER   NOT NULL,
    file_size           INTEGER,
    file_name           VARCHAR(256),
    location            VARCHAR(256),
    uri                 VARCHAR(256),
    cover_date          TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    note                TEXT,
    checked_out         BOOLEAN    NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_media_instance__id PRIMARY KEY (id)
)
    ENGINE            InnoDB
    AUTO_INCREMENT    1024;

-- -----------------------------------------------------------------------------
-- Table media_uri
--
-- Description: Tracks all URIs for stories.
--
CREATE TABLE media_uri (
    id        INTEGER     NOT NULL AUTO_INCREMENT,
    media__id INTEGER     NOT NULL,
    site__id  INTEGER     NOT NULL,
    uri       TEXT            NOT NULL,
    CONSTRAINT pk_media_uri__id PRIMARY KEY (id)
)
    ENGINE            InnoDB
    AUTO_INCREMENT    1024;

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
    id              INTEGER  NOT NULL AUTO_INCREMENT,    
    biz_pkg         INTEGER  NOT NULL,
    name            VARCHAR(32)    NOT NULL,
    function_name   VARCHAR(256)   NOT NULL,
    active          BOOLEAN   NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_media_fields__id PRIMARY KEY (id)
)
    ENGINE            InnoDB
    AUTO_INCREMENT    1024;

-- -----------------------------------------------------------------------------
-- Table media__contributor
-- 
-- Description: mapping tables between media instances and contributors
--
--

CREATE TABLE media__contributor (
    id                  INTEGER   NOT NULL AUTO_INCREMENT,
    media_instance__id  INTEGER   NOT NULL,
    member__id          INTEGER   NOT NULL,
    place               INT2      NOT NULL,
    role                VARCHAR(256),
    CONSTRAINT pk_media_category_id PRIMARY KEY (id)
)
    ENGINE            InnoDB
    AUTO_INCREMENT    1024;


-- -----------------------------------------------------------------------------
-- Table: media_member
-- 
-- Description: The link between media objects and member objects
--

CREATE TABLE media_member (
    id          INTEGER  NOT NULL AUTO_INCREMENT,
    object_id   INTEGER  NOT NULL,
    member__id  INTEGER  NOT NULL,
    CONSTRAINT pk_media_member__id PRIMARY KEY (id)
)
    ENGINE            InnoDB
    AUTO_INCREMENT    1024;


--
-- INDEXES.
--

-- media
CREATE INDEX idx_media__uuid ON media ("uuid" (254));
CREATE INDEX idx_media__first_publish_date ON media(first_publish_date);
CREATE INDEX idx_media__publish_date ON media(publish_date);
CREATE INDEX idx_media_instance__cover_date ON media_instance(cover_date);
CREATE INDEX fkx_source__media ON media(source__id);
CREATE INDEX fkx_usr__media ON media(usr__id);
CREATE INDEX fkx_element_type__media ON media(element_type__id);
CREATE INDEX fkx_site_id__media ON media(site__id);
CREATE INDEX fkx_alias_id__media ON media(alias_id);

-- media_instance
CREATE INDEX idx_media_instance__name ON media_instance(name(254));
CREATE INDEX idx_media_instance__description ON media_instance(description(254));
CREATE INDEX idx_media_instance__file_name ON media_instance(file_name(254));
CREATE INDEX idx_media_instance__uri ON media_instance(uri(254));
CREATE UNIQUE INDEX udx_media__media_instance ON media_instance(media__id, version, checked_out);
CREATE INDEX fkx_usr__media_instance ON media_instance(usr__id);
CREATE INDEX fkx_media_type__media_instance ON media_instance(media_type__id);
CREATE INDEX fkx_category__media_instance ON media_instance(category__id);
CREATE INDEX fkx_primary_oc__media_instance ON media_instance(primary_oc__id);
CREATE INDEX idx_media_instance__note ON media_instance(note(254)) ;

-- media_uri
CREATE INDEX fkx_media__media_uri ON media_uri(media__id);
CREATE UNIQUE INDEX udx_media_uri__site_id__uri ON media_uri(uri (254), site__id);

-- media__output_channel
CREATE INDEX fkx_media__oc__media ON media__output_channel(media_instance__id);
CREATE INDEX fkx_media__oc__oc ON media__output_channel(output_channel__id);

--media__contributor
CREATE INDEX fkx_media__media__contributor ON media__contributor(media_instance__id);
CREATE INDEX fkx_member__media__contributor ON media__contributor(member__id);

-- media_member.
CREATE INDEX fkx_media__media_member ON media_member(object_id);
CREATE INDEX fkx_member__media_member ON media_member(member__id);

CREATE INDEX fkx_media__desk__id ON media(desk__id);
CREATE INDEX fkx_media__workflow__id ON media(workflow__id);

--
-- AUTO_INCREMENT;
-- http://bugs.mysql.com/bug.php?id=21404
--

ALTER TABLE media AUTO_INCREMENT 1024;
ALTER TABLE media_instance AUTO_INCREMENT 1024;
ALTER TABLE media_uri AUTO_INCREMENT 1024;
ALTER TABLE media_fields AUTO_INCREMENT 1024;
ALTER TABLE media__contributor AUTO_INCREMENT 1024;
ALTER TABLE media_member AUTO_INCREMENT 1024;
