-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate$
-- Target DBMS: PostgreSQL 7.2
-- Author: David Wheeler <david@justatheory.com>

-- This DDL creates the basic table for Bric::Person::Usr objects, and
-- establishes its relationship with Bric::Person. The login field must be unique,
-- hence the udx_usr__login index.


-- 
-- TABLE: usr 
--

CREATE TABLE usr (
    id           INTEGER           NOT NULL,
    login        VARCHAR(128)      NOT NULL,
    password     CHAR(32)          NOT NULL,
    active       BOOLEAN           NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_usr__id PRIMARY KEY (id)
);

-- 
-- INDEXES.
--
CREATE INDEX idx_usr__login ON usr(LOWER(login));
CREATE UNIQUE INDEX udx_usr__login ON usr(LOWER(login)) WHERE active = '1';

