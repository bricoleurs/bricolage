-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate$
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@justatheory.com>
--

-- This DDL creates the basic tables for all Bric::BC::Contact objects.

-- 
-- SEQUENCES.
--

CREATE SEQUENCE seq_contact START 1024;
CREATE SEQUENCE seq_contact_value START 1024;

-- 
-- TABLE: contact 
--

CREATE TABLE contact (
    id           NUMERIC(10, 0)    NOT NULL
                                   DEFAULT NEXTVAL('seq_contact'),
    type         VARCHAR(64)       NOT NULL,
    description	 VARCHAR(256),
    active       NUMERIC(1, 0)     NOT NULL 
                                   DEFAULT 1
                                   CONSTRAINT ck_contact__active
                                     CHECK (active IN (1,0)),
    alertable    NUMERIC(1, 0)     NOT NULL 
                                   DEFAULT 0
                                   CONSTRAINT ck_contact__alertable
                                     CHECK (alertable IN (1,0)),
    CONSTRAINT pk_contact__id PRIMARY KEY (id)
);

-- 
-- TABLE: contact_value
--

CREATE TABLE contact_value (
    id           NUMERIC(10, 0)    NOT NULL
                                   DEFAULT NEXTVAL('seq_contact_value'),
    contact__id  NUMERIC(10, 0)    NOT NULL,
    value	 VARCHAR(256)	   NOT NULL,
    active       NUMERIC(1, 0)     NOT NULL 
                                   DEFAULT 1
                                   CONSTRAINT ck_contact_value__active
                                     CHECK (active IN (1,0)),
    CONSTRAINT pk_contact_value__id PRIMARY KEY (id)
);

--
-- TABLE: person__contact
--
CREATE TABLE person__contact_value (
    person__id   NUMERIC(10, 0) NOT NULL,
    contact_value__id  NUMERIC(10, 0) NOT NULL,
    CONSTRAINT pk_person__contact_value PRIMARY KEY (person__id, contact_value__id)
);


-- 
-- INDEXES.
--

CREATE UNIQUE INDEX udx_contact__type ON contact(LOWER(type));
CREATE INDEX idx_contact_value_value ON contact_value(LOWER(value));
CREATE INDEX fdx_contact__contact_value on contact_value(contact__id);

CREATE INDEX fkx_person__p_c_val ON person__contact_value(person__id);
CREATE INDEX fkx_contact_value__p_c_val ON person__contact_value(contact_value__id);
