-- Project: Bricolage
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Garth Webb <garth@perijove.com>
--
-- This is the SQL that will create the element table.
-- It is related to the Bric::ElementType class.
--
--

-- -----------------------------------------------------------------------------
-- Sequences

-- -----------------------------------------------------------------------------
-- Table: element
--
-- Description:    The table that holds the information for a given asset type.  
--         Holds name and description information and is references by 
--        element_type rows.
--

CREATE TABLE at_type (
    id              INTEGER        NOT NULL AUTO_INCREMENT,
    name            VARCHAR(64)       NOT NULL,
    description     VARCHAR(256),
    top_level       BOOLEAN        NOT NULL DEFAULT FALSE,
    paginated       BOOLEAN        NOT NULL DEFAULT FALSE,
    fixed_url       BOOLEAN        NOT NULL DEFAULT FALSE,
    related_story   BOOLEAN        NOT NULL DEFAULT FALSE,
    related_media   BOOLEAN        NOT NULL DEFAULT FALSE,
    media           BOOLEAN        NOT NULL DEFAULT FALSE,
    biz_class__id   INTEGER        NOT NULL,
    active          BOOLEAN        NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_at_type__id PRIMARY KEY (id)
)
    ENGINE          InnoDB 
    AUTO_INCREMENT 1024;

--
-- TABLE: element_type_member
--

CREATE TABLE at_type_member (
    id          INTEGER  NOT NULL AUTO_INCREMENT,
    object_id   INTEGER  NOT NULL,
    member__id  INTEGER  NOT NULL,
    CONSTRAINT pk_at_type_member__id PRIMARY KEY (id)
)
    ENGINE          InnoDB 
    AUTO_INCREMENT 1024;


-- -----------------------------------------------------------------------------
-- Indexes.
--
CREATE UNIQUE INDEX udx_at_type__name ON at_type(name);
CREATE INDEX fkx_class__at_type ON at_type(biz_class__id);
CREATE INDEX fkx_at_type__at_type_member ON at_type_member(object_id);
CREATE INDEX fkx_member__at_type_member ON at_type_member(member__id);

--
-- AUTO_INCREMENT;
-- http://bugs.mysql.com/bug.php?id=21404
--

ALTER TABLE at_type AUTO_INCREMENT 1024;
ALTER TABLE at_type_member AUTO_INCREMENT 1024;
