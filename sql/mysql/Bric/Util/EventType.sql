--
-- ER/Studio 4.0 SQL Code Generation
-- Project:      Bricolage Business API
--
-- Target DBMS : Oracle 8
-- Author: David Wheeler <david@justatheory.com>

-- This DDL creates the basic table for all Bric::Util::EventType objects. It's
-- pretty easy - they're really just all groups.

-- 
-- TABLE: event_type
--

CREATE TABLE event_type (
    id              INTEGER         NOT NULL AUTO_INCREMENT,
    key_name        VARCHAR(64)     NOT NULL,
    name            VARCHAR(64)     NOT NULL,
    description     VARCHAR(256)    NOT NULL,
    class__id       INTEGER         NOT NULL,
    active          BOOLEAN         NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_event_type__id PRIMARY KEY (id)
)
    ENGINE          InnoDB
    AUTO_INCREMENT  1024;

-- 
-- TABLE: event_type_attr
--

CREATE TABLE event_type_attr (
    id              INTEGER         NOT NULL AUTO_INCREMENT,
    event_type__id  INTEGER         NOT NULL,
    name            VARCHAR(64)     NOT NULL,
    CONSTRAINT pk_event_type_attr__id PRIMARY KEY (id)
)
    ENGINE          InnoDB
    AUTO_INCREMENT  1024;


-- 
-- INDEXES.
--

CREATE UNIQUE INDEX udx_event_type__key_name ON event_type(key_name(64));
CREATE UNIQUE INDEX udx_event_type__class_id__name ON event_type(class__id, name(64));

CREATE INDEX fkx_event_type__event_type_attr ON event_type_attr(event_type__id);

CREATE INDEX fkx_class__event_type ON event_type(class__id);

--
-- AUTO_INCREMENT;
-- http://bugs.mysql.com/bug.php?id=21404
--

ALTER TABLE event_type AUTO_INCREMENT 1024;
ALTER TABLE event_type_attr AUTO_INCREMENT 1024;
