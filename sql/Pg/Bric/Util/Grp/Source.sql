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

CREATE SEQUENCE seq_source_member START 1024;

-- 
-- TABLE: source_member 
--

CREATE TABLE source_member (
    id          NUMERIC(10,0)  NOT NULL
                               DEFAULT NEXTVAL('seq_source_member'),
    object_id   NUMERIC(10,0)  NOT NULL,
    member__id  NUMERIC(10,0)  NOT NULL,
    CONSTRAINT pk_source_member__id PRIMARY KEY (id)
);

--
-- INDEXES.
--
CREATE INDEX fkx_source__source_member ON source_member(object_id);
CREATE INDEX fkx_member__source_member ON source_member(member__id);


