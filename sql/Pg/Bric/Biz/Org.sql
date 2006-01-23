-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate$
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@justatheory.com>


-- This DDL creates the table structure for Bric::Org objects.

-- 
-- SEQUENCES.
--

CREATE SEQUENCE seq_org START 1024;

-- 
-- TABLE: org 
--
CREATE TABLE org (
    id           NUMERIC(10, 0)    NOT NULL
                                   DEFAULT NEXTVAL('seq_org'),
    name         VARCHAR(64)       NOT NULL,
    long_name    VARCHAR(128),
    personal     NUMERIC(1, 0)     NOT NULL 
                                   DEFAULT 0
                                   CONSTRAINT ck_org__personal
                                     CHECK (personal IN (1,0)),
    active       NUMERIC(1, 0)     NOT NULL 
                                   DEFAULT 1
                                   CONSTRAINT ck_org__active
                                     CHECK (active IN (1,0)),
    CONSTRAINT pk_org__id PRIMARY KEY (id)
);



-- 
-- INDEXES.
--
CREATE INDEX idx_org__name ON org (LOWER(name));
