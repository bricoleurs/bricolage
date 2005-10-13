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
    id                   NUMERIC(10,0)   NOT NULL
                                         DEFAULT NEXTVAL('seq_story_container_tile'),
    name                 VARCHAR(64)     NOT NULL,
    key_name             VARCHAR(64)     NOT NULL,
    description          VARCHAR(256),
    element__id          NUMERIC(10,0)   NOT NULL,
    object_instance_id   NUMERIC(10,0)   NOT NULL,
    parent_id            NUMERIC(10,0),
    place                NUMERIC(10,0)   NOT NULL,
    object_order         NUMERIC(10,0)   NOT NULL,
    related_instance__id NUMERIC(10,0),
    related_media__id    NUMERIC(10,0),
    active               NUMERIC(1,0)    NOT NULL
                                         DEFAULT 1
                                         CONSTRAINT ck_sc_tile__active
                                           CHECK (active IN (0,1)),

    CONSTRAINT pk_container_tile__id PRIMARY KEY (id)
);


-- -----------------------------------------------------------------------------
-- Table media_container_tile
--
-- Description: Holds the properties of a media container tile
--
--

CREATE TABLE media_container_tile (
    id                          NUMERIC(10,0)   NOT NULL
                                                DEFAULT NEXTVAL('seq_media_container_tile'),
    name                        VARCHAR(64)     NOT NULL,
    key_name                    VARCHAR(64)     NOT NULL,
    description                 VARCHAR(256),
    element__id      	        NUMERIC(10,0)   NOT NULL,
    object_instance_id          NUMERIC(10,0)   NOT NULL,
    parent_id                   NUMERIC(10,0),
    place                       NUMERIC(10,0)   NOT NULL,
    object_order                NUMERIC(10,0)   NOT NULL,

    -- Hack. These two columns never hold values, but keep this table in sync
    -- with story_container_tile, since they share the same code base.
    related_instance__id        NUMERIC(10,0), 
    related_media__id           NUMERIC(10,0),
    active              	NUMERIC(1,0)    NOT NULL
                                                DEFAULT 1
                                                CONSTRAINT ck_mc_tile__active
                                                  CHECK (active IN (0,1)),

    CONSTRAINT pk_media_container_tile__id PRIMARY KEY (id)
);


--
-- INDEXES.
--
CREATE INDEX idx_sc_tile__key_name ON story_container_tile(LOWER(key_name));
CREATE INDEX fkx_sc_tile__sc_tile ON story_container_tile(parent_id);
CREATE INDEX fkx_story__sc_tile ON story_container_tile(object_instance_id);
CREATE INDEX fkx_sc_tile__related_story ON story_container_tile(related_instance__id);
CREATE INDEX fkx_sc_tile__related_media ON story_container_tile(related_media__id);

CREATE INDEX idx_mc_tile__key_name ON media_container_tile(LOWER(key_name));
CREATE INDEX fkx_mc_tile__mc_tile ON media_container_tile(parent_id);
CREATE INDEX fkx_media__mc_tile ON media_container_tile(object_instance_id);
-- These indexes aren't needed unless we decide to relate media to stories at
-- some point.
-- CREATE INDEX fkx_mc_tile__related_story ON media_container_tile(related_instance__id);
-- CREATE INDEX fkx_mc_tile__related_media ON media_container_tile(related_media__id);


