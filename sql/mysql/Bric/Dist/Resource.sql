-- Project: Bricolage Business API
-- File:    Resource.sql
--
-- Author: David Wheeler <david@justatheory.com>
--


-- 
-- TABLE: media__resource 
--

CREATE TABLE media__resource(
    resource__id    INTEGER           NOT NULL,
    media__id       INTEGER           NOT NULL,
    CONSTRAINT pk_media__resource PRIMARY KEY (media__id, resource__id)
)
    ENGINE          InnoDB;


-- 
-- TABLE: resource 
--

CREATE TABLE resource(
    id                  INTEGER           NOT NULL AUTO_INCREMENT,
    parent_id           INTEGER,
    media_type__id      INTEGER           NOT NULL,
    path                VARCHAR(256)      NOT NULL,
    uri                 VARCHAR(256)      NOT NULL,
    size                INTEGER           NOT NULL,
    mod_time            TIMESTAMP         NOT NULL,
    is_dir              BOOLEAN           NOT NULL,
    CONSTRAINT pk_resource__id PRIMARY KEY (id)
)
    ENGINE          InnoDB
    AUTO_INCREMENT  1024;


-- 
-- TABLE: story__resource 
--

CREATE TABLE story__resource(
    story__id       INTEGER           NOT NULL,
    resource__id    INTEGER           NOT NULL,
    CONSTRAINT pk_story__resource PRIMARY KEY (story__id,resource__id)
)
    ENGINE          InnoDB;

-- 
-- INDEXES. 
--

CREATE UNIQUE INDEX udx_resource__path__uri ON resource(path(254), uri(254));
CREATE INDEX idx_resource__path ON resource(path(254));
CREATE INDEX idx_resource__uri ON resource(uri(254));
CREATE INDEX idx_resource__mod_time ON resource(mod_time);
CREATE INDEX fkx_media_type__resource ON resource(media_type__id);
CREATE INDEX fkx_resource__resource ON resource(parent_id);

CREATE INDEX fkx_resource__media__resource ON media__resource(resource__id);
CREATE INDEX fkx_media__media__resource ON media__resource(media__id);

CREATE INDEX fkx_story__story__resource ON story__resource(story__id);
CREATE INDEX fkx_resource__story__resource ON story__resource(resource__id);

--
-- AUTO_INCREMENT;
-- http://bugs.mysql.com/bug.php?id=21404
--

ALTER TABLE resource AUTO_INCREMENT 1024;
