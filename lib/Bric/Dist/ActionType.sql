-- Project: Bricolage
-- VERSION: $Revision: 1.1 $
--
-- $Date: 2001-09-06 21:54:22 $
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@wheeler.net>
--

--
-- SEQUENCES.
--
CREATE SEQUENCE seq_action_type START 1024;


-- 
-- TABLE: action_type 
--

CREATE TABLE action_type (
    id            NUMERIC(10, 0)    NOT NULL
                                    DEFAULT NEXTVAL('seq_action_type'),
    name          VARCHAR(64)       NOT NULL,
    description   VARCHAR(256),
    active        NUMERIC(1, 0)     NOT NULL 
                                    DEFAULT 0
                                    CONSTRAINT ck_action_type__active
                                      CHECK (active IN (1,0)),
    CONSTRAINT pk_action_type__id PRIMARY KEY (id)
);


--
-- TABLE: action_type__media_type
--

CREATE TABLE action_type__media_type (
    action_type__id  NUMERIC(10, 0)    NOT NULL,
    media_type__id    NUMERIC(10, 0)    NOT NULL,
    CONSTRAINT pk_action__media_type PRIMARY KEY (action_type__id, media_type__id)
);


-- 
-- INDEXES. 
--

CREATE UNIQUE INDEX udx_action_type__name ON action_type(LOWER(name));
CREATE INDEX fkx_media_type__at_mt ON action_type__media_type(media_type__id);
CREATE INDEX fkx_action_type__at_mt ON action_type__media_type(action_type__id);


/*
Change Log:
$Log: ActionType.sql,v $
Revision 1.1  2001-09-06 21:54:22  wheeler
Initial revision

*/
