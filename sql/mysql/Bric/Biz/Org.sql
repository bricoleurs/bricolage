-- Project: Bricolage
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@justatheory.com>


-- This DDL creates the table structure for Bric::Org objects.

-- 
-- TABLE: org 
--
CREATE TABLE org (
    id           INTEGER           NOT NULL AUTO_INCREMENT,
    name         VARCHAR(64)       NOT NULL,
    long_name    VARCHAR(128),
    personal     BOOLEAN           NOT NULL DEFAULT FALSE,
    active       BOOLEAN           NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_org__id PRIMARY KEY (id)
)
    ENGINE       InnoDB
    AUTO_INCREMENT 1024;



-- 
-- INDEXES.
--
CREATE INDEX idx_org__name ON org (name(64));

--
-- AUTO_INCREMENT;
-- http://bugs.mysql.com/bug.php?id=21404
--

ALTER TABLE org AUTO_INCREMENT 1024;
