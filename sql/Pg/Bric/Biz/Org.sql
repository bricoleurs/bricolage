-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate$
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@wheeler.net>


-- This DDL creates the table structure for Bric::Org objects.

-- 
-- SEQUENCES.
--

CREATE SEQUENCE seq_org START 1024;

-- 
-- TABLE: org 
--
CREATE TABLE org (
    id           INTEGER           NOT NULL
                                   DEFAULT NEXTVAL('seq_org'),
    name         VARCHAR(64)       NOT NULL,
    long_name    VARCHAR(128),
    personal     BOOLEAN           NOT NULL DEFAULT FALSE,
    active       BOOLEAN           NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_org__id PRIMARY KEY (id)
);



-- 
-- INDEXES.
--
CREATE INDEX idx_org__name ON org (LOWER(name));
