-- Project: Bricolage
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Michael Soderstrom <miraso@pacbell.net>
--

-- ----------------------------------------------------------------------------
-- Table grp
-- 
-- Description: The grp table   Contains the name and description of the
--                 group and its parent if it has one
--

CREATE TABLE grp (
    id           INTEGER          NOT NULL AUTO_INCREMENT,
    parent_id    INTEGER          CHECK (parent_id <> id),
    class__id    INTEGER          NOT NULL,
    name         VARCHAR(64),
    description  VARCHAR(256),
    secret       BOOLEAN          NOT NULL DEFAULT TRUE,
    permanent    BOOLEAN          NOT NULL DEFAULT FALSE,
    active       BOOLEAN          NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_grp__id PRIMARY KEY (id)
)
    ENGINE       InnoDB
    AUTO_INCREMENT 1024;

--
-- INDEXES.
--
CREATE INDEX idx_grp__name ON grp(name(64));
CREATE INDEX idx_grp__description ON grp(description(254));
CREATE INDEX fkx_grp__grp ON grp(parent_id);
CREATE INDEX fkx_class__grp ON grp(class__id);

--
-- AUTO_INCREMENT;
-- http://bugs.mysql.com/bug.php?id=21404
--

ALTER TABLE grp AUTO_INCREMENT 1024;
