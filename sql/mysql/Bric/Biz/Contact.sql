-- Project: Bricolage
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@justatheory.com>
--

-- This DDL creates the basic tables for all Bric::BC::Contact objects.

-- 
-- TABLE: contact 
--

CREATE TABLE contact (
    id           INTEGER           NOT NULL AUTO_INCREMENT,
    type         VARCHAR(64)       NOT NULL,
    description     VARCHAR(256),
    active       BOOLEAN           NOT NULL DEFAULT TRUE,
    alertable    BOOLEAN           NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_contact__id PRIMARY KEY (id)
)
    ENGINE       InnoDB
    AUTO_INCREMENT 1024;

-- 
-- TABLE: contact_value
--

CREATE TABLE contact_value (
    id           INTEGER           NOT NULL AUTO_INCREMENT,
    contact__id  INTEGER           NOT NULL,
    value         VARCHAR(256)       NOT NULL,
    active       BOOLEAN           NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_contact_value__id PRIMARY KEY (id)
)
    ENGINE       InnoDB
    AUTO_INCREMENT 1024;

--
-- TABLE: person__contact
--
CREATE TABLE person__contact_value (
    person__id          INTEGER    NOT NULL,
    contact_value__id   INTEGER    NOT NULL,
    CONSTRAINT pk_person__contact_value PRIMARY KEY (person__id, contact_value__id)
)
    ENGINE       InnoDB
    AUTO_INCREMENT 1024;


-- 
-- INDEXES.
--

CREATE UNIQUE INDEX udx_contact__type ON contact(type);
CREATE INDEX idx_contact_value_value ON contact_value(value);
CREATE INDEX fkx_contact__contact_value on contact_value(contact__id);

CREATE INDEX fkx_person__p_c_val ON person__contact_value(person__id);
CREATE INDEX fkx_contact_value__p_c_val ON person__contact_value(contact_value__id);

--
-- AUTO_INCREMENT;
-- http://bugs.mysql.com/bug.php?id=21404
--

ALTER TABLE contact AUTO_INCREMENT 1024;
ALTER TABLE contact_value AUTO_INCREMENT 1024;
