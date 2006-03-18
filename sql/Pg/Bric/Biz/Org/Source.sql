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
    id            INTEGER           NOT NULL
                                    DEFAULT NEXTVAL('seq_source'),
    org__id       INTEGER           NOT NULL,
    name          VARCHAR(64)       NOT NULL,
    description   VARCHAR(256),
    expire        SMALLINT          NOT NULL DEFAULT 0,
    active        BOOLEAN           DEFAULT TRUE,
    CONSTRAINT pk_source__id PRIMARY KEY (id)
);


-- 
-- INDEXES.
--
CREATE UNIQUE INDEX udx_source_name ON source(name);
CREATE INDEX fkx_source__org on source(org__id);




