-- Project: Bricolage
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Michael Soderstrom <miraso@pacbell.net>
--
-- This is the sql that will create the container elements
--

-- -----------------------------------------------------------------------------
-- Table story_element
-- 
-- Description: Holds the properties of a container element. Note that
--              elements can hold either other container elements or field
--              elements, not both.
--

CREATE TABLE story_element (
    id                   INTEGER         NOT NULL AUTO_INCREMENT,
    element_type__id     INTEGER         NOT NULL,
    object_instance_id   INTEGER         NOT NULL,
    parent_id            INTEGER,
    place                INTEGER         NOT NULL,
    object_order         INTEGER         NOT NULL,
    displayed            BOOLEAN         NOT NULL DEFAULT FALSE,
    related_story__id    INTEGER,
    related_media__id    INTEGER,
    active               BOOLEAN         NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_story_element__id PRIMARY KEY (id)
)
    ENGINE InnoDB
    AUTO_INCREMENT 1024;


-- -----------------------------------------------------------------------------
-- Table media_element
--
-- Description: Holds the properties of a media container element.
--
--

CREATE TABLE media_element (
    id                          INTEGER         NOT NULL  AUTO_INCREMENT,
    element_type__id            INTEGER         NOT NULL,
    object_instance_id          INTEGER         NOT NULL,
    parent_id                   INTEGER,
    place                       INTEGER         NOT NULL,
    object_order                INTEGER         NOT NULL,
    displayed                   BOOLEAN         NOT NULL DEFAULT FALSE,
    related_story__id           INTEGER, 
    related_media__id           INTEGER,
    active                      BOOLEAN         NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_media_element__id PRIMARY KEY (id)
)
    ENGINE InnoDB
    AUTO_INCREMENT 1024;


--
-- INDEXES.
--
CREATE INDEX fkx_story_element__story_element ON story_element(parent_id);
CREATE INDEX fkx_story__story_element ON story_element(object_instance_id);
CREATE INDEX fkx_story_element__related_story ON story_element(related_story__id);
CREATE INDEX fkx_story_element__related_media ON story_element(related_media__id);
CREATE INDEX fkx_story_element__element_type ON story_element(element_type__id);

CREATE INDEX fkx_media_element__media_element ON media_element(parent_id);
CREATE INDEX fkx_media__media_element ON media_element(object_instance_id);
CREATE INDEX fkx_media_element__related_story ON media_element(related_story__id);
CREATE INDEX fkx_media_element__related_media ON media_element(related_media__id);
CREATE INDEX fkx_media_element__element_type ON media_element(element_type__id);

--
-- AUTO_INCREMENT;
-- http://bugs.mysql.com/bug.php?id=21404
--

ALTER TABLE story_element AUTO_INCREMENT 1024;
ALTER TABLE media_element AUTO_INCREMENT 1024;
