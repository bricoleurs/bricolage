-- Project: Bricolage
--
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
    id           INTEGER          NOT NULL
                                DEFAULT NEXTVAL('seq_language'),
    name         VARCHAR(64),
    description  VARCHAR(256),
    active       BOOLEAN        NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_language__id PRIMARY KEY (id)
);

CREATE UNIQUE INDEX udx_language__name ON language(LOWER(name));

*/


