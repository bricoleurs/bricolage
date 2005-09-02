-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate$
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Michael Soderstrom <miraso@pacbell.net>
--
-- This is the sql that will create the container and data tiles
--

-- -----------------------------------------------------------------------------
-- Sequences

-- Unique IDs for the story container_tile table
CREATE SEQUENCE seq_story_container_tile START  1024;

-- Unique IDs for the media container tile table
CREATE SEQUENCE seq_media_container_tile START  1024;

-- -----------------------------------------------------------------------------
-- Table story_container_tile
-- 
-- Description:	Holds the properties of a container tile.   Note that tiles
--				can hold either other tiles or data, not both.
--

CREATE TABLE story_container_tile (
    id                   INTEGER         NOT NULL
                                         DEFAULT NEXTVAL('seq_container_tile'),
    name                 VARCHAR(64)     NOT NULL,
    key_name             VARCHAR(64)     NOT NULL,
    description          VARCHAR(256),
    element__id          INTEGER         NOT NULL,
    object_instance_id   INTEGER         NOT NULL,
    parent_id            INTEGER,
    place                INTEGER         NOT NULL,
    object_order         INTEGER         NOT NULL,
    related_story__id INTEGER,
    related_media__id    INTEGER,
    active               BOOLEAN         NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_container_tile__id PRIMARY KEY (id)
);


-- -----------------------------------------------------------------------------
-- Table media_container_tile
--
-- Description: Holds the properties of a media container tile
--
--

CREATE TABLE media_container_tile (
    id                          INTEGER         NOT NULL
                                                DEFAULT NEXTVAL('seq_media_container_tile'),
    name                        VARCHAR(64)     NOT NULL,
    key_name                    VARCHAR(64)     NOT NULL,
    description                 VARCHAR(256),
    element__id      	        INTEGER         NOT NULL,
    object_instance_id          INTEGER         NOT NULL,
    parent_id                   INTEGER,
    place                       INTEGER         NOT NULL,
    object_order                INTEGER         NOT NULL,
    related_story__id        INTEGER, 
    related_media__id           INTEGER,
    active              	    BOOLEAN         NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_media_container_tile__id PRIMARY KEY (id)
);


--
-- INDEXES.
--
CREATE INDEX idx_sc_tile__key_name ON story_container_tile(LOWER(key_name));
CREATE INDEX fkx_sc_tile__sc_tile ON story_container_tile(parent_id);
CREATE INDEX fkx_story__sc_tile ON story_container_tile(object_instance_id);
CREATE INDEX fkx_sc_tile__related_story ON story_container_tile(related_story__id);
CREATE INDEX fkx_sc_tile__related_media ON story_container_tile(related_media__id);

CREATE INDEX idx_mc_tile__key_name ON media_container_tile(LOWER(key_name));
CREATE INDEX fkx_mc_tile__mc_tile ON media_container_tile(parent_id);
CREATE INDEX fkx_media__mc_tile ON media_container_tile(object_instance_id);
CREATE INDEX fkx_mc_tile__related_story ON media_container_tile(related_story__id);
CREATE INDEX fkx_mc_tile__related_media ON media_container_tile(related_media__id);


