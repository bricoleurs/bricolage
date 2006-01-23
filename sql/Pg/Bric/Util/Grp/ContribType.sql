-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate$
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@justatheory.com>



CREATE SEQUENCE seq_contrib_type_member START 1024;


--
-- TABLE: contrib_type_member
--

CREATE TABLE contrib_type_member (
    id          NUMERIC(10,0)  NOT NULL
                               DEFAULT NEXTVAL('seq_contrib_type_member'),
    object_id   NUMERIC(10,0)  NOT NULL,
    member__id  NUMERIC(10,0)  NOT NULL,
    CONSTRAINT pk_contrib_type_member__id PRIMARY KEY (id)
);






CREATE INDEX fkx_contrib_type__ctype_member ON contrib_type_member(object_id);
CREATE INDEX fkx_member__ctype_member ON contrib_type_member(member__id);


