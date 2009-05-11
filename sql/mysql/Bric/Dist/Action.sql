-- Project: Bricolage
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@justatheory.com>
--

-- 
-- TABLE: action 
--

CREATE TABLE action (
    id               INTEGER           NOT NULL AUTO_INCREMENT,
    ord              INT2              NOT NULL,
    server_type__id  INTEGER           NOT NULL,
    action_type__id  INTEGER           NOT NULL,
    active           BOOLEAN           NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_action__id PRIMARY KEY (id)
)
    ENGINE           InnoDB
    AUTO_INCREMENT   1024;


-- 
-- TABLE: attr_action
--

CREATE TABLE attr_action (
    id         INTEGER       NOT NULL AUTO_INCREMENT,
    subsys     VARCHAR(256)  NOT NULL,
    name       VARCHAR(256)  NOT NULL,
    sql_type   VARCHAR(30)   NOT NULL,
    active     BOOLEAN       NOT NULL DEFAULT TRUE,
   CONSTRAINT pk_attr_action__id PRIMARY KEY (id)
)
    ENGINE           InnoDB
    AUTO_INCREMENT   1024;


-- 
-- TABLE: attr_action_val
--

CREATE TABLE attr_action_val (
    id           INTEGER         NOT NULL AUTO_INCREMENT,
    object__id   INTEGER         NOT NULL,
    attr__id     INTEGER         NOT NULL,
    date_val     DATETIME,
    short_val    VARCHAR(1024),
    blob_val     TEXT,
    serial       BOOLEAN         DEFAULT FALSE,
    active       BOOLEAN         NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_attr_action_val__id PRIMARY KEY (id)
)
    ENGINE           InnoDB
    AUTO_INCREMENT   1024;


-- 
-- TABLE: attr_action_meta
--

CREATE TABLE attr_action_meta (
    id        INTEGER         NOT NULL AUTO_INCREMENT,
    attr__id  INTEGER         NOT NULL,
    name      VARCHAR(256)    NOT NULL,
    value     VARCHAR(2048),
    active    BOOLEAN         NOT NULL DEFAULT TRUE,
   CONSTRAINT pk_attr_action_meta__id PRIMARY KEY (id)
)
    ENGINE           InnoDB
    AUTO_INCREMENT   1024;

-- 
-- INDEXES. 
--
CREATE INDEX fkx_action_type__action ON action(action_type__id);
CREATE INDEX fkx_server_type__action ON action(server_type__id);

-- Unique index on subsystem/name pair
CREATE UNIQUE INDEX udx_attr_action__subsys__name ON attr_action(subsys(254), name(254));

-- Indexes on name and subsys.
CREATE INDEX idx_attr_action__name ON attr_action(name(254));
CREATE INDEX idx_attr_action__subsys ON attr_action(subsys(254));

-- Unique index on object__id/attr__id pair
CREATE UNIQUE INDEX udx_attr_action_val__obj_attr ON attr_action_val (object__id,attr__id);

-- FK indexes on object__id and attr__id.
CREATE INDEX fkx_action__attr_action_val ON attr_action_val(object__id);
CREATE INDEX fkx_attr_action__attr_action_val ON attr_action_val(attr__id);

-- Unique index on attr__id/name pair
CREATE UNIQUE INDEX udx_attr_action_meta__attr_name ON attr_action_meta (attr__id, name(254));

-- Index on meta name.
CREATE INDEX idx_attr_action_meta__name ON attr_action_meta(name(254));

-- FK index on attr__id.
CREATE INDEX fkx_attr_action__attr_action_meta ON attr_action_meta(attr__id);

--
-- AUTO_INCREMENT;
-- http://bugs.mysql.com/bug.php?id=21404
--

ALTER TABLE action AUTO_INCREMENT 1024;
ALTER TABLE attr_action AUTO_INCREMENT 1024;
ALTER TABLE attr_action_val AUTO_INCREMENT 1024;
ALTER TABLE attr_action_meta AUTO_INCREMENT 1024;
