-- Project: Bricolage
-- VERSION: $Revision: 1.1.1.1.2.1 $
--
-- $Date: 2001-10-09 21:51:08 $
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@wheeler.net>
--

-- 
-- TABLE: alert_type_member 
--

CREATE TABLE alert_type_member (
    id          NUMERIC(10,0)  NOT NULL
                               DEFAULT NEXTVAL('seq_alert_type_member'),
    object_id   NUMERIC(10,0)  NOT NULL,
    member__id  NUMERIC(10,0)  NOT NULL,
    CONSTRAINT pk_alert_type_member__id PRIMARY KEY (id)
);

-- 
-- SEQUENCES.
--

CREATE SEQUENCE seq_alert_type_member START 1024;

--
-- INDEXES.
--
CREATE INDEX fkx_alert_type__alert_type_member ON alert_type_member(object_id);
CREATE INDEX fkx_member__alert_type_member ON alert_type_member(member__id);



