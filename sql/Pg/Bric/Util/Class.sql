-- Project: Bricolage
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Garth Webb <garth@perijove.com>
--
-- This is the SQL that will create the class table.
--

-- -----------------------------------------------------------------------------
-- Sequences

-- Unique IDs for the class table
CREATE SEQUENCE seq_class START 1024;

-- -----------------------------------------------------------------------------
-- TABLE: class 
--        For keeping track of Perl classes.

CREATE TABLE class(
    id              INTEGER         NOT NULL
                                    DEFAULT NEXTVAL('seq_class'),
    key_name        VARCHAR(32)     NOT NULL
                                    CONSTRAINT ck_class__key_name
                                    CHECK (LOWER(key_name) = key_name),
    pkg_name        VARCHAR(128)    NOT NULL,
    disp_name       VARCHAR(128)    NOT NULL,
    plural_name        VARCHAR(128)    NOT NULL,
    description     VARCHAR(256),
    distributor     BOOLEAN         NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_class__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Indexes.
--

CREATE UNIQUE INDEX udx_class__key_name ON class(LOWER(key_name));
CREATE UNIQUE INDEX udx_class__pkg_name ON class(LOWER(pkg_name));
CREATE UNIQUE INDEX udx_class__disp__name ON class(LOWER(disp_name));

