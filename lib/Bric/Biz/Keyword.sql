-- Project: Bricolage
-- VERSION: $Revision: 1.2 $
--
-- $Date: 2001-10-09 20:48:53 $
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Garth Webb <garth@perijove.com>
--
-- This SQL creates the tables necessary for the keyword object.
--

-- -----------------------------------------------------------------------------
-- Sequences

-- Unique IDs for the main keyword table
CREATE SEQUENCE seq_keyword START 1024;

-- Unique IDs for the keyword member table
CREATE SEQUENCE seq_keyword_member START 1024;



-- -----------------------------------------------------------------------------
-- Table: KEYWORD
--
-- Description: The main keyword table.

CREATE TABLE keyword (
    id               NUMERIC(10)   NOT NULL
                                   DEFAULT NEXTVAL('seq_keyword'),
    name             VARCHAR(256)  NOT NULL,
    screen_name      VARCHAR(256)  NOT NULL,
    sort_name        VARCHAR(256)  NOT NULL,
    meaning          VARCHAR(512),
    prefered         NUMERIC(1)	   NOT NULL
                                   DEFAULT 1
                                   CONSTRAINT ck_keyword__prefered
                                     CHECK (prefered IN (0,1)),
    synonym_grp_id   NUMERIC(10),
    active           NUMERIC(1)	   NOT NULL
                                   DEFAULT 1
                                   CONSTRAINT ck_keyword__active
                                     CHECK (active IN (0,1)),
    CONSTRAINT pk_keyword__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table: keyword_member
-- 
-- Description: The link between keyword objects and member objects
--

CREATE TABLE keyword_member (
    id          NUMERIC(10,0)  NOT NULL
                               DEFAULT NEXTVAL('seq_keyword_member'),
    object_id   NUMERIC(10,0)  NOT NULL,
    member__id  NUMERIC(10,0)  NOT NULL,
    CONSTRAINT pk_keyword_member__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Indexes

CREATE UNIQUE INDEX udx_keyword__name ON keyword(LOWER(name));
CREATE UNIQUE INDEX udx_keyword__screen_name ON keyword(LOWER(screen_name));
CREATE INDEX idx_keyword__sort_name ON keyword(LOWER(sort_name));
CREATE INDEX fkx_keyword__grp ON keyword(synonym_grp_id);

CREATE INDEX fkx_keyword__keyword_member ON keyword_member(object_id);
CREATE INDEX fkx_member__keyword_member ON keyword_member(member__id);


