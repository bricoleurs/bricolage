-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate$
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Michael Soderstrom <miraso@pacbell.net>

/*

-- ----------------------------------------------------------------------------
-- Sequences

-- Unique IDs for the async table
CREATE SEQUENCE seq_async  START  1024; 

-- ----------------------------------------------------------------------------
-- Table async
-- 

CREATE TABLE async (
    id           NUMERIC(10,0) NOT NULL
                               DEFAULT NEXTVAL('seq_async'),
    name         VARCHAR(32)   NOT NULL,
    description  VARCHAR(256),
    file_name    VARCHAR(128),
    active       NUMERIC(1,0)  NOT NULL
                               DEFAULT 1
                               CONSTRAINT ck_async__active
                                          CHECK (active IN (0,1)),
    CONSTRAINT pk_async__id PRIMARY KEY (id)
);


-- 
-- INDEXES.
--
 
CREATE UNIQUE INDEX udx_async__file_name ON async(LOWER(file_name));
CREATE INDEX idx_async__name ON async(LOWER(name));

*/


