-- Project: Bricolage
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@justatheory.com>
--

-- 
-- TABLE: action_type 
--

CREATE TABLE action_type (
    id            INTEGER           NOT NULL AUTO_INCREMENT,
    name          VARCHAR(64)       NOT NULL,
    description   VARCHAR(256),
    active        BOOLEAN           NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_action_type__id PRIMARY KEY (id)
)
    ENGINE        InnoDB
    AUTO_INCREMENT 1024;


--
-- TABLE: action_type__media_type
--

CREATE TABLE action_type__media_type (
    action_type__id   INTEGER          NOT NULL,
    media_type__id    INTEGER          NOT NULL,
    CONSTRAINT pk_action__media_type PRIMARY KEY (action_type__id, media_type__id)
)
    ENGINE        InnoDB
    AUTO_INCREMENT 1024;


-- 
-- INDEXES. 
--

CREATE UNIQUE INDEX udx_action_type__name ON action_type(name(64));
CREATE INDEX fkx_media_type__at_mt ON action_type__media_type(media_type__id);
CREATE INDEX fkx_action_type__at_mt ON action_type__media_type(action_type__id);

--
-- AUTO_INCREMENT;
-- http://bugs.mysql.com/bug.php?id=21404
--

ALTER TABLE action_type AUTO_INCREMENT 1024;
