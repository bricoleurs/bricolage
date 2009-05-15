-- Project: Bricolage
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@justatheory.com>

-- This DDL creates the table structure for Bric::Org::Person objects.

-- 
-- TABLE: person_org 
--
CREATE TABLE person_org(
    id            INTEGER           NOT NULL AUTO_INCREMENT,
    person__id    INTEGER           NOT NULL,
    org__id       INTEGER           NOT NULL,
    role          VARCHAR(64),
    department    VARCHAR(64),
    title         VARCHAR(64),
    active        BOOLEAN           NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_person_org__id PRIMARY KEY (id)
)
    ENGINE       InnoDB
    AUTO_INCREMENT 1024;


-- 
-- INDEXES.
--
CREATE UNIQUE INDEX udx_person_org__person__org ON person_org(person__id, org__id, role(64));
CREATE INDEX idx_person_org__department ON person_org(department(64));
CREATE INDEX fkx_person__person_org ON person_org(person__id);
CREATE INDEX fkx_org__person_org ON person_org(org__id);

--
-- AUTO_INCREMENT;
-- http://bugs.mysql.com/bug.php?id=21404
--

ALTER TABLE person_org AUTO_INCREMENT 1024;
