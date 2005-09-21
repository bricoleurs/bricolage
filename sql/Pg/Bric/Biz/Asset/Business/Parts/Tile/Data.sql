-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate$
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Michael Soderstrom <miraso@pacbell.net>
--

-- -----------------------------------------------------------------------------
-- Sequences

-- Unique IDs for the story data tiles
CREATE SEQUENCE seq_story_field START 1024;

-- Unique IDs for the media data tile table
CREATE SEQUENCE seq_media_field START 1024;

-- -----------------------------------------------------------------------------
-- Table story_field
--
-- Description: Story Data tiles are story specific mappings to the 
--              Bric::Asset::Business::Parts::Tile::Data class.
--              They link to the story that this tile is a part of,
--              the attribute id of the data that is contained with in,
--              and it's parent's id ( a story_element row ).
--              Place is it's order and active is it's active state.
--
--

CREATE TABLE story_field (
    id                   INTEGER        NOT NULL
                                        DEFAULT NEXTVAL('seq_story_field'),
    field_type__id       INTEGER        NOT NULL,
    object_instance_id   INTEGER        NOT NULL,
    parent_id            INTEGER        NOT NULL,
    hold_val             BOOLEAN        NOT NULL DEFAULT FALSE,
    place                INTEGER        NOT NULL,
    object_order         INTEGER        NOT NULL,
    date_val             TIMESTAMP,
    short_val            TEXT,
    blob_val             TEXT,
    active               BOOLEAN        NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_story_field__id PRIMARY KEY (id)
);


-- -----------------------------------------------------------------------------
-- Table media_field
--
-- Description: Media Data tiles are media specific mappings to the 
--              Bric::Asset::Business::Parts::Tile::Data class.
--              They link to the media that this tile is a part of,
--              the attribute id of the data that is contained with in,
--              and it's parent's id ( a story_element row ).
--              Place is it's order and active is it's active state.
--
--

CREATE TABLE media_field (
    id                   INTEGER        NOT NULL
                                        DEFAULT NEXTVAL('seq_media_field'),
    field_type__id       INTEGER        NOT NULL,
    object_instance_id   INTEGER        NOT NULL,
    parent_id            INTEGER        NOT NULL,
    place                INTEGER        NOT NULL,
    hold_val             BOOLEAN        NOT NULL DEFAULT FALSE,
    object_order         INTEGER        NOT NULL,
    date_val             TIMESTAMP,
    short_val            VARCHAR(1024),
    blob_val             TEXT,
    active               BOOLEAN        NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_media_field__id PRIMARY KEY (id)
);

--
-- INDEXES.
--
CREATE INDEX fkx_story_instance__story_field ON story_field(object_instance_id);
CREATE INDEX fkx_field_type__story_field ON story_field(field_type__id);
CREATE INDEX fkx_sc_tile__story_field ON story_field(parent_id);

CREATE INDEX fkx_media_instance__media_field ON media_field(object_instance_id);
CREATE INDEX fkx_field_type__media_field ON media_field(field_type__id);
CREATE INDEX fkx_sc_tile__media_field ON media_field(parent_id);
