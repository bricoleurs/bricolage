--
-- Project: Bricolage API
--
-- Author: David Wheeler <david@justatheory.com>

-- 
-- TABLE: grp_priv 
--        Privileges granted to user groups.

CREATE TABLE grp_priv (
    id         INTEGER           NOT NULL AUTO_INCREMENT,
    grp__id    INTEGER           NOT NULL,
    value      INT2              NOT NULL
                                   CHECK (value BETWEEN 1 AND 255),
    mtime      TIMESTAMP         NOT NULL
                                 DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_grp_priv__id PRIMARY KEY (id)
)
    ENGINE     InnoDB
    AUTO_INCREMENT 1024;


-- 
-- TABLE: grp_priv__grp_member 
--        Ties group privileges to groups for whose members the privilege
--        is granted.

CREATE TABLE grp_priv__grp_member (
    grp_priv__id    INTEGER           NOT NULL,
    grp__id         INTEGER           NOT NULL,
    CONSTRAINT pk_grp_priv__grp_member PRIMARY KEY (grp_priv__id,grp__id)
)
    ENGINE     InnoDB;

--
-- INDEXES.
--
CREATE INDEX fkx_grp__grp_priv ON grp_priv(grp__id);
CREATE INDEX fkx_grp__grp_priv__grp_member ON grp_priv__grp_member(grp__id);
CREATE INDEX fkx_grp_priv__grp_priv__grp_member ON grp_priv__grp_member(grp_priv__id);

-- Everything below is left as a note for the future - in case we ever decided
-- actually allow privileges granted to individual users and/or individual
-- objects.

/*
-- 
-- TABLE: grp_priv__grp 
--

CREATE TABLE grp_priv__grp(
    grp_priv__id    INTEGER           NOT NULL,
    grp__id         INTEGER           NOT NULL,
    CONSTRAINT pk_grp_priv__grp PRIMARY KEY (grp_priv__id,grp__id)
) 
;


-- 
-- TABLE: grp_priv__person 
--

CREATE TABLE grp_priv__person(
    grp_priv__id    INTEGER           NOT NULL,
    person__id      INTEGER           NOT NULL,
    CONSTRAINT pk_grp_priv__person PRIMARY KEY (grp_priv__id,person__id)
) 
;


-- 
-- TABLE: grp_priv__usr 
--

CREATE TABLE grp_priv__usr(
    grp_priv__id    INTEGER           NOT NULL,
    usr__id        INTEGER           NOT NULL,
    CONSTRAINT pk_grp_priv__usr PRIMARY KEY (grp_priv__id,usr__id)
) 
;


-- 
-- TABLE: priv_table 
--

CREATE TABLE priv_table(
    id      INTEGER           NOT NULL,
    name    VARCHAR(30)    NOT NULL,
    CONSTRAINT pk_priv_table__id PRIMARY KEY (id)
) 
;


-- 
-- TABLE: usr_priv 
--

CREATE TABLE usr_priv(
    id          INTEGER           NOT NULL,
    usr__id    INTEGER           NOT NULL,
    value       INT2     NOT NULL,
    CONSTRAINT pk_usr_priv__id PRIMARY KEY (id)
) 
;


-- 
-- TABLE: usr_priv__grp 
--

CREATE TABLE usr_priv__grp(
    priv_usr__id    INTEGER           NOT NULL,
    grp__id          INTEGER           NOT NULL,
    CONSTRAINT pk_usr_priv__grp PRIMARY KEY (priv_usr__id,grp__id)
) 
;


-- 
-- TABLE: usr_priv__person 
--

CREATE TABLE usr_priv__person(
    usr_priv__id    INTEGER           NOT NULL,
    person__id       INTEGER           NOT NULL,
    CONSTRAINT pk_usr_priv__person PRIMARY KEY (usr_priv__id,person__id)
) 
;


-- 
-- TABLE: usr_priv__usr 
--

CREATE TABLE usr_priv__usr(
    usr_priv__id    INTEGER           NOT NULL,
    usr__id         INTEGER           NOT NULL,
    CONSTRAINT pk_usr_priv__usr PRIMARY KEY (usr_priv__id,usr__id)
) 
;


-- 
-- TABLE: usr_priv__grp_member 
--

CREATE TABLE usr_priv__grp_member(
    usr_priv__id    INTEGER           NOT NULL,
    grp__id          INTEGER           NOT NULL,
    CONSTRAINT pk_usr_priv__grp_member PRIMARY KEY (usr_priv__id,grp__id)
) 
;

*/

--
-- AUTO_INCREMENT;
-- http://bugs.mysql.com/bug.php?id=21404
--

ALTER TABLE grp_priv AUTO_INCREMENT 1024;
