-- Project: Bricolage
-- VERSION: $Revision: 1.3 $
--
-- $Date: 2001-10-11 00:34:54 $
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@wheeler.net>


-- This DDL creates the basic tables for Bric::Util::Event objects.

-- 
-- SEQUENCES.
--
CREATE SEQUENCE seq_event START 1024;


-- 
-- TABLE: event 
--

CREATE TABLE event (
    id                NUMERIC(10, 0)    NOT NULL
                                        DEFAULT NEXTVAL('seq_attr_person'),
    event_type__id    NUMERIC(10, 0)    NOT NULL,
    usr__id           NUMERIC(10, 0)    NOT NULL,
    obj_id            NUMERIC(10, 0)    NOT NULL,
    timestamp         TIMESTAMP         NOT NULL
                                        DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_event__id PRIMARY KEY (id)
);

-- 
-- TABLE: event_attr
--
CREATE TABLE event_attr (
    event__id            NUMERIC(10, 0)   NOT NULL,
    event_type_attr__id  NUMERIC(10, 0)   NOT NULL,
    value                VARCHAR(128)
);

--
-- INDEXES.
--

CREATE INDEX fkx_event_type__event ON event(event_type__id);
CREATE INDEX fkx_usr__event ON event(usr__id);
CREATE INDEX idx_event__timestamp ON event(timestamp);

CREATE INDEX fkx_event__event_attr ON event_attr(event__id);
CREATE INDEX fkx_event_type_attr__event_attr ON event_attr(event_type_attr__id);


