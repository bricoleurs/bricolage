--
-- Project: Bricolage Business API
--
-- Author: David Wheeler <david@justatheory.com>


-- This DDL creates the table structure for Bric::BC::Org::Source objects.

-- 
-- TABLE: source
--

CREATE TABLE source (
    id            INTEGER           NOT NULL AUTO_INCREMENT,
    org__id       INTEGER           NOT NULL,
    name          VARCHAR(64)       NOT NULL,
    description   VARCHAR(256),
    expire        SMALLINT          NOT NULL DEFAULT 0,
    active        BOOLEAN           DEFAULT TRUE,
    CONSTRAINT pk_source__id PRIMARY KEY (id)
)
    ENGINE        InnoDB
    AUTO_INCREMENT 1024;


-- 
-- INDEXES.
--
CREATE UNIQUE INDEX udx_source_name ON source(name(64));
CREATE INDEX fkx_source__org on source(org__id);

--
-- AUTO_INCREMENT;
-- http://bugs.mysql.com/bug.php?id=21404
--

ALTER TABLE source AUTO_INCREMENT 1024;
