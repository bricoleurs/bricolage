-- Project: Bricolage
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Michael Soderstrom <miraso@pacbell.net>
--

/* Commented out because we're not using language stuff at this point.
   By David.


-- -----------------------------------------------------------------------------
-- Table: language
--
-- Description: name and description of languages 
--              

CREATE TABLE language (
    id           INTEGER          NOT NULL AUTO_INCREMENT,
    name         VARCHAR(64),
    description  VARCHAR(256),
    active       BOOLEAN        NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_language__id PRIMARY KEY (id)
);

CREATE UNIQUE INDEX udx_language__name ON language(name(64));

--
-- AUTO_INCREMENT;
-- http://bugs.mysql.com/bug.php?id=21404
--

ALTER TABLE language AUTO_INCREMENT 1024;

*/
