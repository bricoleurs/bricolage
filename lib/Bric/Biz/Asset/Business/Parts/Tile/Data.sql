-- Project: Bricolage
-- VERSION: $Revision: 1.1.1.1.2.1 $
--
-- $Date: 2001-10-09 21:51:06 $
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Michael Soderstrom <miraso@pacbell.net>
--

-- ------------------------------------------------------------------------------- Sequences

-- Unique IDs for the story data tiles
CREATE SEQUENCE seq_story_data_tile START 1024;

-- Unique IDs for the media data tile table
CREATE SEQUENCE seq_media_data_tile START 1024;

-- ------------------------------------------------------------------------------- Table story_data_tile
--
-- Description: Story Data tiles are story specific mappings to the 
--              Bric::Asset::Business::Parts::Tile::Data class.
--              They link to the story that this tile is a part of,
--              the attribute id of the data that is contained with in,
--              and it's parent's id ( a story_container_tile row ).
--              Place is it's order and active is it's active state.
--
--

CREATE TABLE story_data_tile (
    id                   NUMERIC(10,0)  NOT NULL
                                        DEFAULT NEXTVAL('seq_story_data_tile'),
    name                 VARCHAR(32),
    description          VARCHAR(256),
    element_data__id  NUMERIC(10,0)  NOT NULL,
    object_instance_id   NUMERIC(10,0)  NOT NULL,
    parent_id            NUMERIC(10,0)  NOT NULL,
    hold_val             NUMERIC(1,0)   NOT NULL
                                        DEFAULT 0
                                        CONSTRAINT ck_sd_tile__hold_val
                                          CHECK (hold_val IN (0,1)),
    place                NUMERIC(10,0)  NOT NULL,
    object_order         NUMERIC(10,0)  NOT NULL,
    date_val             TIMESTAMP,
    short_val            VARCHAR(1024),
    blob_val             TEXT,
    active               NUMERIC(1,0)   NOT NULL
                                        DEFAULT 1
                                        CONSTRAINT ck_sd_tile__active
                                          CHECK (active IN (0,1)),
    CONSTRAINT pk_story_data_tile__id PRIMARY KEY (id)
);


-- -----------------------------------------------------------------------------
-- Table media_data_tile
--
-- Description: Media Data tiles are media specific mappings to the 
--              Bric::Asset::Business::Parts::Tile::Data class.
--              They link to the media that this tile is a part of,
--              the attribute id of the data that is contained with in,
--              and it's parent's id ( a story_container_tile row ).
--              Place is it's order and active is it's active state.
--
--

CREATE TABLE media_data_tile (
    id                   NUMERIC(10,0)  NOT NULL
                                        DEFAULT NEXTVAL('seq_media_data_tile'),
    name                 VARCHAR(32),
    description          VARCHAR(256),
    element_data__id  NUMERIC(10,0)  NOT NULL,
    object_instance_id   NUMERIC(10,0)  NOT NULL,
    parent_id            NUMERIC(10,0)  NOT NULL,
    place                NUMERIC(10,0)  NOT NULL,
    hold_val             NUMERIC(1,0)   NOT NULL
                                        DEFAULT 0
                                        CONSTRAINT ck_md_tile__hold_val
                                          CHECK (hold_val IN (0,1)),
    object_order         NUMERIC(10,0)  NOT NULL,
    date_val             TIMESTAMP,
    short_val            VARCHAR(1024),
    blob_val             TEXT,
    active               NUMERIC(1,0)   NOT NULL
                                        DEFAULT 1
                                        CONSTRAINT ck_md_tile__active
                                          CHECK (active IN (0,1)),
    CONSTRAINT pk_media_data_tile__id PRIMARY KEY (id)
);

--
-- INDEXES.
--
CREATE INDEX idx_story_data_tile__name ON story_data_tile(LOWER(name));
CREATE INDEX fkx_story_instance__sd_tile ON story_data_tile(object_instance_id);
CREATE INDEX fkx_element__sd_tile ON story_data_tile(element_data__id);
CREATE INDEX fkx_sc_tile__sd_tile ON story_data_tile(parent_id);

CREATE INDEX idx_media_data_tile__name ON media_data_tile(LOWER(name));
CREATE INDEX fkx_media_instance__md_tile ON media_data_tile(object_instance_id);
CREATE INDEX fkx_element__md_tile ON media_data_tile(element_data__id);
CREATE INDEX fkx_sc_tile__md_tile ON media_data_tile(parent_id);


