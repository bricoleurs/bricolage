-- Project: Bricolage
-- VERSION: $Revision: 1.3 $
--
-- $Date: 2001-10-11 00:34:54 $
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Michael Soderstrom <miraso@pacbell.net>
--

/* Commented out because we're not using language stuff at this point.
   By David.


-- -----------------------------------------------------------------------------
-- Sequences

-- Unique IDs for the language table
-- IDs under 1024 will contain dead languages
CREATE SEQUENCE seq_language START 1024;


-- -----------------------------------------------------------------------------
-- Table: language
--
-- Description: name and description of languages 
--              

CREATE TABLE language (
    id           NUMERIC(10,0)	NOT NULL
                                DEFAULT NEXTVAL('seq_language'),
    name         VARCHAR(64),
    description  VARCHAR(256),
    active       NUMERIC(1)     NOT NULL
                                DEFAULT 1
                                CONSTRAINT ck_language__active
                                  CHECK (active IN (0,1)),
    CONSTRAINT pk_language__id PRIMARY KEY (id)
);

CREATE UNIQUE INDEX udx_language__name ON language(LOWER(name));

*/


