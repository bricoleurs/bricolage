-- Project: Bricolage
--
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
--                 group and its parent if it has one
--

CREATE TABLE grp (
    id           INTEGER          NOT NULL
                                  DEFAULT NEXTVAL('seq_grp'),
    parent_id    INTEGER          CONSTRAINT ck_grp__parent_id_not_eq_id
                                    CHECK (parent_id <> id),
    class__id    INTEGER          NOT NULL,
    name         VARCHAR(64),
    description  VARCHAR(256),
    secret       BOOLEAN          NOT NULL DEFAULT TRUE,
    permanent    BOOLEAN          NOT NULL DEFAULT FALSE,
    active       BOOLEAN          NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_grp__id PRIMARY KEY (id)
);

--
-- INDEXES.
--
CREATE INDEX idx_grp__name ON grp(LOWER(name));
CREATE INDEX idx_grp__description ON grp(LOWER(description));
CREATE INDEX fkx_grp__grp ON grp(parent_id);
CREATE INDEX fkx_class__grp ON grp(class__id);



