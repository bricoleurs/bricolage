-- Project: Bricolage Business API
-- File:    ServerType.sql
--
-- Author: David Wheeler <david@justatheory.com>
--

-- 
-- TABLE: server_type 
--

CREATE TABLE server_type(
    id             INTEGER           NOT NULL AUTO_INCREMENT,
    class__id      INTEGER           NOT NULL,
    name           VARCHAR(64)       NOT NULL,
    description    VARCHAR(256),
    site__id       INTEGER           NOT NULL,
    copyable       BOOLEAN           NOT NULL DEFAULT FALSE,
    publish        BOOLEAN           NOT NULL DEFAULT TRUE,
    preview        BOOLEAN           NOT NULL DEFAULT FALSE,
    active         BOOLEAN           NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_server_type__id PRIMARY KEY (id)
)
    ENGINE         InnoDB
    AUTO_INCREMENT 1024;


-- 
-- TABLE: server_type__output__channel
--

CREATE TABLE server_type__output_channel(
    server_type__id    INTEGER         NOT NULL,
    output_channel__id INTEGER         NOT NULL,
    CONSTRAINT pk_server_type__output_channel
      PRIMARY KEY (server_type__id, output_channel__id)
)
    ENGINE         InnoDB;


--
-- TABLE: dest_member
--

CREATE TABLE dest_member (
    id          INTEGER        NOT NULL AUTO_INCREMENT,
    object_id   INTEGER        NOT NULL,
    member__id  INTEGER        NOT NULL,
    CONSTRAINT pk_dest_member__id PRIMARY KEY (id)
)
    ENGINE         InnoDB
    AUTO_INCREMENT 1024;


-- 
-- Indexes.
--
CREATE UNIQUE INDEX udx_server_type__name_site
ON server_type(name(64), site__id);

CREATE INDEX fkx_site__server_type ON server_type(site__id);
CREATE INDEX fkx_class__server_type ON server_type(class__id);

CREATE INDEX fkx_server_type__st_oc ON server_type__output_channel(server_type__id);
CREATE INDEX fk_output_channel__st_oc ON server_type__output_channel(output_channel__id);

CREATE INDEX fkx_dest__dest_member ON dest_member(object_id);
CREATE INDEX fkx_member__dest_member ON dest_member(member__id);

--
-- AUTO_INCREMENT;
-- http://bugs.mysql.com/bug.php?id=21404
--

ALTER TABLE server_type AUTO_INCREMENT 1024;
ALTER TABLE dest_member AUTO_INCREMENT 1024;
