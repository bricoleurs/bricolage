-- Project: Bricolage
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@justatheory.com>


-- This DDL creates the basic tables for Bric::Util::Event objects.

-- 
-- TABLE: event 
--

CREATE TABLE event (
    id                INTEGER           NOT NULL AUTO_INCREMENT,
    event_type__id    INTEGER           NOT NULL,
    usr__id           INTEGER           NOT NULL,
    obj_id            INTEGER           NOT NULL,
    timestamp         TIMESTAMP         NOT NULL
                                        DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_event__id PRIMARY KEY (id)
)
    ENGINE            InnoDB
    AUTO_INCREMENT    1024;

-- 
-- TABLE: event_attr
--
CREATE TABLE event_attr (
    id                   INTEGER          NOT NULL AUTO_INCREMENT,
    event__id            INTEGER          NOT NULL,
    event_type_attr__id  INTEGER          NOT NULL,
    value                VARCHAR(128),
    CONSTRAINT pk_event_attr__id PRIMARY KEY (id)
)
    ENGINE            InnoDB
    AUTO_INCREMENT    1024;

--
-- INDEXES.
--

CREATE INDEX fkx_event_type__event ON event(event_type__id);
CREATE INDEX fkx_usr__event ON event(usr__id);
CREATE INDEX idx_event__timestamp ON event(timestamp);
CREATE INDEX idx_event__obj_id ON event(obj_id);

CREATE INDEX fkx_event__event_attr ON event_attr(event__id);
CREATE INDEX fkx_event_type_attr__event_attr ON event_attr(event_type_attr__id);

--
-- AUTO_INCREMENT;
-- http://bugs.mysql.com/bug.php?id=21404
--

ALTER TABLE event AUTO_INCREMENT 1024;
ALTER TABLE event_attr AUTO_INCREMENT 1024;
