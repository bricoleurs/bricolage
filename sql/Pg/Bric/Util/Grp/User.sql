-- Project: Bricolage
-- VERSION: $Revision: 1.1 $
--
-- $Date: 2003-02-02 19:46:48 $
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@wheeler.net>
--

-- 
-- TABLE: user_member 
--

CREATE TABLE user_member (
    id          NUMERIC(10,0)  NOT NULL
                               DEFAULT NEXTVAL('seq_user_member'),
    object_id   NUMERIC(10,0)  NOT NULL,
    member__id  NUMERIC(10,0)  NOT NULL,
    CONSTRAINT pk_user_member__id PRIMARY KEY (id)
);

-- 
-- SEQUENCES.
--

CREATE SEQUENCE seq_user_member START 1024;

--
-- INDEXES.
--
CREATE INDEX fkx_user__user_member ON user_member(object_id);
CREATE INDEX fkx_member__user_member ON user_member(member__id);



