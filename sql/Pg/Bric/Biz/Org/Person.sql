-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- $Id$
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@justatheory.com>

-- This DDL creates the table structure for Bric::Org::Person objects.

-- 
-- SEQUENCES.
--

CREATE SEQUENCE seq_person_org START 1024;

-- 
-- TABLE: person_org 
--
CREATE TABLE person_org(
    id            INTEGER           NOT NULL
                                    DEFAULT NEXTVAL('seq_person_org'),
    person__id    INTEGER           NOT NULL,
    org__id       INTEGER           NOT NULL,
    role          VARCHAR(64),
    department    VARCHAR(64),
    title         VARCHAR(64),
    active        BOOLEAN           NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_person_org__id PRIMARY KEY (id)
);


-- 
-- INDEXES.
--
CREATE UNIQUE INDEX udx_person_org__person__org ON person_org(person__id, org__id, role);
CREATE INDEX idx_person_org__department ON person_org(LOWER(department));
CREATE INDEX fkx_person__person_org ON person_org(person__id);
CREATE INDEX fkx_org__person_org ON person_org(org__id);
