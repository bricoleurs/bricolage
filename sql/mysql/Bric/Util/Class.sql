-- Project: Bricolage
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Garth Webb <garth@perijove.com>
--
-- This is the SQL that will create the class table.
--

-- -----------------------------------------------------------------------------
-- TABLE: class 
--        For keeping track of Perl classes.

CREATE TABLE class(
    id              INTEGER         NOT NULL AUTO_INCREMENT,
    key_name        VARCHAR(32)     NOT NULL
                                    CHECK (LOWER(key_name) = key_name),
    pkg_name        VARCHAR(128)    NOT NULL,
    disp_name       VARCHAR(128)    NOT NULL,
    plural_name        VARCHAR(128)    NOT NULL,
    description     VARCHAR(256),
    distributor     BOOLEAN         NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_class__id PRIMARY KEY (id)
)
    ENGINE          InnoDB
    AUTO_INCREMENT  1024;

-- -----------------------------------------------------------------------------
-- Indexes.
--

CREATE UNIQUE INDEX udx_class__key_name ON class(key_name(32));
CREATE UNIQUE INDEX udx_class__pkg_name ON class(pkg_name(128));
CREATE UNIQUE INDEX udx_class__disp__name ON class(disp_name(128));

--
-- AUTO_INCREMENT;
-- http://bugs.mysql.com/bug.php?id=21404
--

ALTER TABLE class AUTO_INCREMENT 1024;
