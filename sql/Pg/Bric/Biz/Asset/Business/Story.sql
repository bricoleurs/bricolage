-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate$
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Michael Soderstrom <miraso@pacbell.net>
--
--
-- This is the SQL representation of the story object
--

-- -----------------------------------------------------------------------------
-- Sequences

-- Unique IDs for the story table
CREATE SEQUENCE seq_story START  1024;

-- Unique IDs for the story_instance table
CREATE SEQUENCE seq_story_instance START 1024;

-- Unique IDs for the story__category mapping table
CREATE SEQUENCE seq_story__category START  1024;

-- Unique ids for the story_contributor table
CREATE SEQUENCE seq_story__contributor START 1024;

-- Unique IDs for the attr_story table
CREATE SEQUENCE seq_attr_story START 1024;

-- Unique IDs for each attr_story_*_val table
CREATE SEQUENCE seq_attr_story_val START 1024;

-- Unique IDs for the story_meta table
CREATE SEQUENCE seq_attr_story_meta START 1024;

-- Unique IDs for the story_uri table
CREATE SEQUENCE seq_story_uri START 1024;


-- -----------------------------------------------------------------------------
-- Table: story
--
-- Description: The story properties. Versioning info might get added here and
--              the rights info might get removed. It is also possible that
--              the asset type field will need a cascading delete.


CREATE TABLE story (
    id                NUMERIC(10,0)   NOT NULL
                                      DEFAULT NEXTVAL('seq_story'),
    priority          NUMERIC(1,0)    NOT NULL
                                      DEFAULT 3
                                      CONSTRAINT ck_story__priority
                                        CHECK (priority BETWEEN 1 AND 5),
    source__id        NUMERIC(10,0)   NOT NULL, 
    usr__id           NUMERIC(10,0),
    element__id       NUMERIC(10,0)   NOT NULL,
    primary_uri       VARCHAR(128),
    first_publish_date TIMESTAMP,
    publish_date      TIMESTAMP,
    expire_date       TIMESTAMP,
    cover_date        TIMESTAMP,
    current_version   NUMERIC(10, 0)  NOT NULL,
    published_version NUMERIC(10, 0),
    workflow__id      NUMERIC(10,0)   NOT NULL,
    desk__id          NUMERIC(10,0)   NOT NULL,
    publish_status    NUMERIC(1,0)    NOT NULL
                                      DEFAULT 0,
    active            NUMERIC(1,0)    NOT NULL
                                      DEFAULT 1
                                      CONSTRAINT ck_story__active
                                        CHECK (active IN (0,1)),
    site__id          NUMERIC(10,0)   NOT NULL,
    alias_id          NUMERIC(10,0)   CONSTRAINT ck_story_id
                                        CHECK (alias_id != id),  
    CONSTRAINT pk_story__id PRIMARY KEY (id)
);

-- ----------------------------------------------------------------------------
-- Table story_instance
--
-- Description:  An instance of a story
--

CREATE TABLE story_instance (
    id             NUMERIC(10,0)   NOT NULL
                                  DEFAULT NEXTVAL('seq_story_instance'),
    name           VARCHAR(256),
    description    VARCHAR(1024),
    story__id      NUMERIC(10,0)   NOT NULL,
    version        NUMERIC(10,0),
    usr__id        NUMERIC(10,0)   NOT NULL,
    slug           VARCHAR(64),
    primary_oc__id NUMERIC(10,0)   NOT NULL,
    checked_out    NUMERIC(1,0)    NOT NULL
                                   DEFAULT 0
                                   CONSTRAINT ck_story_instance__checked_out
                                     CHECK (checked_out IN (0,1)),
    CONSTRAINT pk_story_instance__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table story_uri
--
-- Description: Tracks all URIs for stories.
--
CREATE TABLE story_uri (
    id        NUMERIC(10,0)   NOT NULL
                              DEFAULT NEXTVAL('seq_story_uri'),
    story__id NUMERIC(10)     NOT NULL,
    site__id NUMERIC(10)      NOT NULL,
    uri       TEXT            NOT NULL,
    CONSTRAINT pk_story_uri__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table story__output_channel
-- 
-- Description: Mapping Table between stories and output channels.
--
--

CREATE TABLE story__output_channel (
    story_instance__id  NUMERIC(10, 0)  NOT NULL,
    output_channel__id  NUMERIC(10, 0)  NOT NULL,
    CONSTRAINT pk_story_output_channel
      PRIMARY KEY (story_instance__id, output_channel__id)
);


-- -----------------------------------------------------------------------------
-- Table story__category
-- 
-- Description: Mapping Table between Stories and categories
--
--

CREATE TABLE story__category (
    id                  NUMERIC(10,0)  NOT NULL
                                       DEFAULT NEXTVAL('seq_story__category'),
    story_instance__id  NUMERIC(10,0)  NOT NULL,
    category__id        NUMERIC(10,0)  NOT NULL,
    main                NUMERIC(1,0)   NOT NULL
                                       DEFAULT 0
                                       CONSTRAINT ck_story__category__main
                                         CHECK (main IN (0,1)),
    CONSTRAINT pk_story_category__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table story__contributor
-- 
-- Description: mapping tables between story instances and contributors
--
--

CREATE TABLE story__contributor (
    id                  NUMERIC(10,0)   NOT NULL
                                        DEFAULT NEXTVAL('seq_story__contributor'),
    story_instance__id  NUMERIC(10,0)   NOT NULL,
    member__id          NUMERIC(10,0)   NOT NULL,
    place               NUMERIC(3,0)    NOT NULL,
    role                VARCHAR(256),
    CONSTRAINT pk_story_category_id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table attr_story
--
-- Description: Attributes for stories
--

CREATE TABLE attr_story (
    id         NUMERIC(10)   NOT NULL
                             DEFAULT NEXTVAL('seq_attr_story'),
    subsys     VARCHAR(256)  NOT NULL,
    name       VARCHAR(256)  NOT NULL,
    sql_type   VARCHAR(30)   NOT NULL,
    active     NUMERIC(1)    DEFAULT 1
                             NOT NULL
                             CONSTRAINT ck_attr_story__active
                               CHECK (active IN (0,1)),
   CONSTRAINT pk_attr_story__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table attr_story_val
--
-- Description: Values for the story attributes
-- 
--

CREATE TABLE attr_story_val (
    id           NUMERIC(10)     NOT NULL
                                 DEFAULT NEXTVAL('seq_attr_story_val'),
    object__id   NUMERIC(10)     NOT NULL,
    attr__id     NUMERIC(10)     NOT NULL,
    date_val     TIMESTAMP,
    short_val    VARCHAR(1024),
    blob_val     TEXT,
    serial       NUMERIC(1)      DEFAULT 0,
    active       NUMERIC(1)      DEFAULT 1
                                 NOT NULL
                                 CONSTRAINT ck_attr_story_val__active
                                   CHECK (active IN (0,1)),
    CONSTRAINT pk_attr_story_val__id PRIMARY KEY (id)
);


-- -----------------------------------------------------------------------------
-- Table attr_story_meta
--
-- Description: Meta information on story attributes
--

CREATE TABLE attr_story_meta (
    id        NUMERIC(10)     NOT NULL
                              DEFAULT NEXTVAL('seq_attr_story_meta'),
    attr__id  NUMERIC(10)     NOT NULL,
    name      VARCHAR(256)    NOT NULL,
    value     VARCHAR(2048),
    active    NUMERIC(1)      DEFAULT 1
                              NOT NULL
                              CONSTRAINT ck_attr_story_meta__active
                                CHECK (active IN (0,1)),
   CONSTRAINT pk_attr_story_meta__id PRIMARY KEY (id)
);


-- -----------------------------------------------------------------------------
-- Indexes.
--

-- story
CREATE INDEX idx_story__primary_uri ON story(LOWER(primary_uri));
CREATE INDEX fdx_usr__story ON story(usr__id);
CREATE INDEX fdx_source__story ON story(source__id);
CREATE INDEX fdx_element__story ON story(element__id);
CREATE INDEX fdx_site_id__story ON story(site__id);
CREATE INDEX fdx_alias_id__story ON story(alias_id);
CREATE INDEX idx_story__first_publish_date ON story(first_publish_date);
CREATE INDEX idx_story__publish_date ON story(publish_date);
CREATE INDEX idx_story__cover_date ON story(cover_date);

-- story_instance
CREATE INDEX idx_story_instance__name ON story_instance(LOWER(name));
CREATE INDEX idx_story_instance__description ON story_instance(LOWER(description));
CREATE INDEX idx_story_instance__slug ON story_instance(LOWER(slug));
CREATE INDEX fdx_story__story_instance ON story_instance(story__id);
CREATE INDEX fdx_usr__story_instance ON story_instance(usr__id);
CREATE INDEX fdx_primary_oc__story_instance ON story_instance(primary_oc__id);

-- story_uri
CREATE INDEX fkx_story__story_uri ON story_uri(story__id);
CREATE UNIQUE INDEX udx_story_uri__site_id__uri
ON story_uri(lower_text_num(uri, site__id));

-- story__category
CREATE UNIQUE INDEX udx_story_category__story__cat ON story__category(story_instance__id, category__id);
CREATE INDEX fkx_story__story__category ON story__category(story_instance__id);
CREATE INDEX fkx_category__story__category ON story__category(category__id);

-- story__output_channel
CREATE INDEX fkx_story__oc__story ON story__output_channel(story_instance__id);
CREATE INDEX fkx_story__oc__oc ON story__output_channel(output_channel__id);

--story__contributor
CREATE INDEX fkx_story__story__contributor ON story__contributor(story_instance__id);
CREATE INDEX fkx_member__story__contributor ON story__contributor(member__id);

-- Unique index on subsystem/name pair
CREATE UNIQUE INDEX udx_attr_story__subsys__name ON attr_story(subsys, name);

-- Indexes on name and subsys.
CREATE INDEX idx_attr_story__name ON attr_story(LOWER(name));
CREATE INDEX idx_attr_story__subsys ON attr_story(LOWER(subsys));

-- Unique index on object__id/attr__id pair
CREATE UNIQUE INDEX udx_attr_story_val__obj_attr ON attr_story_val (object__id,attr__id);

-- FK indexes on object__id and attr__id.
CREATE INDEX fkx_story__attr_story_val ON attr_story_val(object__id);
CREATE INDEX fkx_attr_story__attr_story_val ON attr_story_val(attr__id);

-- Unique index on attr__id/name pair
CREATE UNIQUE INDEX udx_attr_story_meta__attr_name ON attr_story_meta (attr__id, name);

-- Index on meta name.
CREATE INDEX idx_attr_story_meta__name ON attr_story_meta(LOWER(name));

-- FK index on attr__id.
CREATE INDEX fkx_attr_story__attr_story_meta ON attr_story_meta(attr__id);

CREATE INDEX fdx_story__desk__id ON story(desk__id) WHERE desk__id > 0;
CREATE INDEX fdx_story__workflow__id ON story(workflow__id) WHERE workflow__id > 0;
