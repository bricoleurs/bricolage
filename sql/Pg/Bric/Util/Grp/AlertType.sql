-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate$
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@justatheory.com>
--

-- 
-- SEQUENCES.
--

CREATE SEQUENCE seq_alert_type_member START 1024;

-- 
-- TABLE: alert_type_member 
--

CREATE TABLE alert_type_member (
    id          INTEGER        NOT NULL
                               DEFAULT NEXTVAL('seq_alert_type_member'),
    object_id   INTEGER        NOT NULL,
    member__id  INTEGER        NOT NULL,
    CONSTRAINT pk_alert_type_member__id PRIMARY KEY (id)
);

--
-- INDEXES.
--
CREATE INDEX fkx_alert_type__alert_type_member ON alert_type_member(object_id);
CREATE INDEX fkx_member__alert_type_member ON alert_type_member(member__id);



