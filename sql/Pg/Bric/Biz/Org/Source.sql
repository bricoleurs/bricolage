--
-- Project: Bricolage Business API
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate$
-- Author: David Wheeler <david@justatheory.com>


-- This DDL creates the table structure for Bric::BC::Org::Source objects.

-- 
-- SEQUENCES.
--

CREATE SEQUENCE seq_source START 1024;


-- 
-- TABLE: source
--

CREATE TABLE source (
    id            NUMERIC(10, 0)    NOT NULL
                                    DEFAULT NEXTVAL('seq_source'),
    org__id       NUMERIC(10, 0)    NOT NULL,
    name          VARCHAR(64)       NOT NULL,
    description   VARCHAR(256),
    expire        NUMERIC(4, 0)     NOT NULL
				    DEFAULT 0,
    active        NUMERIC(1, 0)     CONSTRAINT ck_source__active CHECK (active IN (1,0))
                                    DEFAULT 1,
    CONSTRAINT pk_source__id PRIMARY KEY (id)
);


-- 
-- INDEXES.
--
CREATE UNIQUE INDEX udx_source_name ON source(name);
CREATE INDEX fkx_source__org on source(org__id);




