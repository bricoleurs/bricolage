-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate: 2006-03-18 03:10:10 +0200 (Sat, 18 Mar 2006) $
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@justatheory.com>
--

-- 
-- TABLE: media_type 
--

CREATE TABLE media_type (
    id             INTEGER           NOT NULL AUTO_INCREMENT,
    name           VARCHAR(128)      NOT NULL,
    description    VARCHAR(256),
    active         BOOLEAN           NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_media_type__id PRIMARY KEY (id)
)
    ENGINE         InnoDB
    AUTO_INCREMENT 1024;


-- 
-- TABLE: media_type_ext
--

CREATE TABLE media_type_ext (
    id                  INTEGER           NOT NULL AUTO_INCREMENT,
    media_type__id      INTEGER           NOT NULL,
    extension           VARCHAR(10)       NOT NULL,
    CONSTRAINT pk_media_type_ext__id PRIMARY KEY (id)
)
    ENGINE         InnoDB
    AUTO_INCREMENT 1024;


--
-- TABLE: media_type_member
--

CREATE TABLE media_type_member (
    id          INTEGER        NOT NULL AUTO_INCREMENT,
    object_id   INTEGER        NOT NULL,
    member__id  INTEGER        NOT NULL,
    CONSTRAINT pk_media_type_member__id PRIMARY KEY (id)
)
    ENGINE         InnoDB
    AUTO_INCREMENT 1024;


-- 
-- INDEXES. 
--

CREATE UNIQUE INDEX udx_media_type__name ON media_type(name(128));
CREATE UNIQUE INDEX udx_media_type_ext__extension ON media_type_ext(extension(10));
CREATE INDEX fkx_media_type__media_type_ext ON media_type_ext(media_type__id);
CREATE INDEX fkx_media_type__media_type_member ON media_type_member(object_id);
CREATE INDEX fkx_member__media_type_member ON media_type_member(member__id);


