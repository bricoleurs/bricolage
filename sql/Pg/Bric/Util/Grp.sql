-- Project: Bricolage
-- VERSION: $Revision: 1.2 $
--
-- $Date: 2003-03-12 09:01:07 $
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Michael Soderstrom <miraso@pacbell.net>
--

-- ----------------------------------------------------------------------------
-- Sequences

-- Unique IDs for the grp table
CREATE SEQUENCE seq_grp START  1024; 

-- ----------------------------------------------------------------------------
-- Table grp
-- 
-- Description: The grp table   Contains the name and description of the
-- 				group and its parent if it has one
--

CREATE TABLE grp (
    id           NUMERIC(10,0)    NOT NULL
                                  DEFAULT NEXTVAL('seq_grp'),
    parent_id    NUMERIC(10,0)    CONSTRAINT ck_grp__parent_id_not_eq_id
                                    CHECK (parent_id <> id),
    class__id    NUMERIC(10,0)    NOT NULL,
    name         VARCHAR(64),
    description  VARCHAR(256),
    secret       NUMERIC(1,0)     NOT NULL
                                  DEFAULT 1
                                  CONSTRAINT ck_grp__secret
                                    CHECK (secret IN (0,1)),
    permanent    NUMERIC(1,0)     NOT NULL
                                  DEFAULT 0
                                  CONSTRAINT ck_grp__permanent
                                    CHECK (permanent IN (0,1)),
    active      NUMERIC(1,0)      NOT NULL
                                  DEFAULT 1
                                  CONSTRAINT ck_grp__active
                                    CHECK (active IN (0,1)),
    CONSTRAINT pk_grp__id PRIMARY KEY (id)
);

--
-- INDEXES.
--
CREATE INDEX idx_grp__name ON grp(LOWER(name));
CREATE INDEX idx_grp__description ON grp(LOWER(description));
CREATE INDEX fkx_grp__grp ON grp(parent_id);
CREATE INDEX fkx_class__grp ON grp(class__id);



