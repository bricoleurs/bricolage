-- Project: Bricolage
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Garth Webb <garth@perijove.com>
--
-- This SQL creates the tables necessary for the keyword object.
--

-- -----------------------------------------------------------------------------
-- Sequences

-- Unique IDs for the main keyword table
CREATE SEQUENCE seq_keyword START 1024;
CREATE SEQUENCE seq_keyword_member START 1024;


-- -----------------------------------------------------------------------------
-- Table: KEYWORD
--
-- Description: The main keyword table.

CREATE TABLE keyword (
    id               INTEGER       NOT NULL
                                   DEFAULT NEXTVAL('seq_keyword'),
    name             VARCHAR(256)  NOT NULL,
    screen_name      VARCHAR(256)  NOT NULL,
    sort_name        VARCHAR(256)  NOT NULL,
    active           BOOLEAN       NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_keyword__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table: story_keyword
-- 
-- Description: The link between stories and keywords
--

CREATE TABLE story_keyword (
    story_id          INTEGER  NOT NULL,
    keyword_id        INTEGER  NOT NULL,
    CONSTRAINT pk_story_keyword PRIMARY KEY (story_id, keyword_id)
);


-- -----------------------------------------------------------------------------
-- Table: media_keyword
-- 
-- Description: The link between media and keywords
--

CREATE TABLE media_keyword (
    media_id         INTEGER  NOT NULL,
    keyword_id       INTEGER  NOT NULL,
    CONSTRAINT pk_media_keyword PRIMARY KEY (media_id, keyword_id)
);

-- -----------------------------------------------------------------------------
-- Table: category_keyword
-- 
-- Description: The link between categories and keywords
--

CREATE TABLE category_keyword (
    category_id       INTEGER  NOT NULL,
    keyword_id        INTEGER  NOT NULL,
    CONSTRAINT pk_category_keyword PRIMARY KEY (category_id, keyword_id)
);

--
-- TABLE: keyword_member
--

CREATE TABLE keyword_member (
    id          INTEGER  NOT NULL
                         DEFAULT NEXTVAL('seq_keyword_member'),
    object_id   INTEGER  NOT NULL,
    member__id  INTEGER  NOT NULL,
    CONSTRAINT pk_keyword_member__id PRIMARY KEY (id)
);




-- -----------------------------------------------------------------------------
-- Indexes

CREATE UNIQUE INDEX udx_keyword__name ON keyword(LOWER(name));
CREATE INDEX idx_keyword__screen_name ON keyword(LOWER(screen_name));
CREATE INDEX idx_keyword__sort_name   ON keyword(LOWER(sort_name));

CREATE INDEX fkx_keyword__keyword_member ON keyword_member(object_id);
CREATE INDEX fkx_member__keyword_member ON keyword_member(member__id);

CREATE INDEX fkx_keyword__story_keyword ON story_keyword(keyword_id);
CREATE INDEX fkx_story__story_keyword ON story_keyword(story_id);

CREATE INDEX fkx_keyword__media_keyword ON media_keyword(keyword_id);
CREATE INDEX fkx_media__media_keyword ON media_keyword(media_id);

CREATE INDEX fkx_keyword__category_keyword ON category_keyword(keyword_id);
CREATE INDEX fkx_category__category_keyword ON category_keyword(category_id);
