-- Project: Bricolage
-- VERSION: $Revision: 1.1.1.1.2.1 $
--
-- $Date: 2001-10-09 21:51:06 $
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Garth Webb <garth@perijove.com>
--
-- This is the SQL that will create the element table.
-- It is related to the Bric::AssetType class.
-- Related tables are element_container and element_data
--
--

-- -----------------------------------------------------------------------------
-- Sequences

-- Unique IDs for the element table
CREATE SEQUENCE seq_at_type START 1024;
CREATE SEQUENCE seq_element_type_member START 1024;

-- -----------------------------------------------------------------------------
-- Table: element
--
-- Description:	The table that holds the information for a given asset type.  
-- 		Holds name and description information and is references by 
--		element_contaner and element_data rows.
--

CREATE TABLE at_type (
    id              NUMERIC(10,0)  NOT NULL
                                   DEFAULT NEXTVAL('seq_at_type'),
    name            VARCHAR(64)	   NOT NULL,
    description     VARCHAR(256),
    top_level       NUMERIC(1,0)   NOT NULL
                                   DEFAULT 0
                                   CONSTRAINT ck_at_type__top_level
                                     CHECK (top_level IN (0,1)),
    paginated       NUMERIC(1,0)   NOT NULL
                                   DEFAULT 0
                                   CONSTRAINT ck_at_type__paginated
                                     CHECK (paginated IN (0,1)),
    fixed_url       NUMERIC(1,0)   NOT NULL
                                   DEFAULT 0
                                   CONSTRAINT ck_at_type__fixed_url
                                     CHECK (fixed_url IN (0,1)),
    related_story   NUMERIC(1,0)   NOT NULL
                                   DEFAULT 0
                                   CONSTRAINT ck_at_type__related_story
                                     CHECK (related_story IN (0,1)),
    related_media   NUMERIC(1,0)   NOT NULL
                                   DEFAULT 0
                                   CONSTRAINT ck_at_type__related_media
                                     CHECK (related_media IN (0,1)),
    media           NUMERIC(1,0)   NOT NULL
                                   DEFAULT 0
                                   CONSTRAINT ck_at_type__media
                                     CHECK (media IN (0,1)),
    biz_class__id   NUMERIC(10,0)  NOT NULL,
    active          NUMERIC(1,0)   NOT NULL
                                   DEFAULT 1
                                   CONSTRAINT ck_at_type__active
                                     CHECK (active IN (0,1)),
    CONSTRAINT pk_at_type__id PRIMARY KEY (id)
);

--
-- TABLE: element_type_member
--

CREATE TABLE element_type_member (
    id          NUMERIC(10,0)  NOT NULL
                               DEFAULT NEXTVAL('seq_element_type_member'),
    object_id   NUMERIC(10,0)  NOT NULL,
    member__id  NUMERIC(10,0)  NOT NULL,
    CONSTRAINT pk_element_type_member__id PRIMARY KEY (id)
);


-- -----------------------------------------------------------------------------
-- Indexes.
--
CREATE UNIQUE INDEX udx_at_type__name ON at_type(LOWER(name));
CREATE INDEX fdx_class__at_type ON at_type(biz_class__id);
CREATE INDEX fkx_comp_type__comp_type_member ON element_type_member(object_id);
CREATE INDEX fkx_member__comp_type_member ON element_type_member(member__id);


