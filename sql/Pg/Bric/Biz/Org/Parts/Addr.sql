-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@justatheory.com>


-- This DDL creates the table structure for Bric::Org::Parts::Address objects.

-- 
-- SEQUENCES.
--

CREATE SEQUENCE seq_addr START 1024;
CREATE SEQUENCE seq_addr_part START 1024;
CREATE SEQUENCE seq_addr_part_type START 1024;


-- 
-- TABLE: addr 
--

CREATE TABLE addr (
    id         INTEGER             NOT NULL
                                   DEFAULT NEXTVAL('seq_addr'),
    org__id    INTEGER             NOT NULL,
    type       VARCHAR(64),
    active     BOOLEAN             NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_addr__id PRIMARY KEY (id)
);


-- 
-- TABLE: addr_part_type 
--

CREATE TABLE addr_part_type (
    id         INTEGER             NOT NULL
                                   DEFAULT NEXTVAL('seq_addr_part_type'),
    name      VARCHAR(64)          NOT NULL,
    active     BOOLEAN             NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_addr_part_type__id PRIMARY KEY (id)
);


-- 
-- TABLE: addr_part
--

CREATE TABLE addr_part (
    id                    INTEGER         NOT NULL
                                          DEFAULT NEXTVAL('seq_addr_part'),
    addr__id              INTEGER         NOT NULL,
    addr_part_type__id    INTEGER         NOT NULL,
    value                 VARCHAR(256)    NOT NULL,
    CONSTRAINT pk_addr_part__id PRIMARY KEY (id)
);

-- 
-- TABLE: person_org__addr 
--

CREATE TABLE person_org__addr(
    addr__id          INTEGER           NOT NULL,
    person_org__id    INTEGER           NOT NULL,
    CONSTRAINT pk_person_org__addr__all PRIMARY KEY (addr__id,person_org__id)
);


--
-- INDEXES.
--
CREATE INDEX idx_addr__type ON addr(LOWER(type));
CREATE UNIQUE INDEX udx_addr_part_type__name ON addr_part_type(LOWER(name));
CREATE INDEX idx_addr_part__value ON addr_part(LOWER(value));

CREATE INDEX fkx_org__addr ON addr(org__id);
CREATE INDEX fkx_addr__addr_part ON addr_part(addr__id);
CREATE INDEX fkx_addr_part_type__addr_part ON addr_part(addr_part_type__id);
CREATE INDEX fkx_addr__person_org_addr ON person_org__addr(addr__id);
CREATE INDEX fk_person_org__pers_org_addr ON person_org__addr(person_org__id);
