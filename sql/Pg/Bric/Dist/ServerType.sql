-- Project: Bricolage Business API
-- File:    ServerType.sql
-- VERSION: $LastChangedRevision$
--
-- Author: David Wheeler <david@justatheory.com>
--

-- 
-- Sequences.
--
CREATE SEQUENCE seq_server_type START 1024;
CREATE SEQUENCE seq_dest_member START 1024;

-- 
-- TABLE: server_type 
--

CREATE TABLE server_type(
    id             INTEGER           NOT NULL
                                     DEFAULT NEXTVAL('seq_server_type'),
    class__id      INTEGER           NOT NULL,
    name           VARCHAR(64)       NOT NULL,
    description    VARCHAR(256),
    site__id       INTEGER           NOT NULL,
    copyable       BOOLEAN           NOT NULL DEFAULT FALSE,
    publish        BOOLEAN           NOT NULL DEFAULT TRUE,
    preview        BOOLEAN           NOT NULL DEFAULT FALSE,
    active         BOOLEAN           NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_server_type__id PRIMARY KEY (id)
);


-- 
-- TABLE: server_type__output__channel
--

CREATE TABLE server_type__output_channel(
    server_type__id    INTEGER         NOT NULL,
    output_channel__id INTEGER         NOT NULL,
    CONSTRAINT pk_server_type__output_channel
      PRIMARY KEY (server_type__id, output_channel__id)
);


--
-- TABLE: dest_member
--

CREATE TABLE dest_member (
    id          INTEGER        NOT NULL
                               DEFAULT NEXTVAL('seq_dest_member'),
    object_id   INTEGER        NOT NULL,
    member__id  INTEGER        NOT NULL,
    CONSTRAINT pk_dest_member__id PRIMARY KEY (id)
);


-- 
-- Indexes.
--
CREATE UNIQUE INDEX udx_server_type__name_site
ON server_type(lower_text_num(name, site__id));

CREATE INDEX fkx_site__server_type ON server_type(site__id);
CREATE INDEX fkx_class__server_type ON server_type(class__id);

CREATE INDEX fkx_server_type__st_oc ON server_type__output_channel(server_type__id);
CREATE INDEX fk_output_channel__st_oc ON server_type__output_channel(output_channel__id);

CREATE INDEX fkx_dest__dest_member ON dest_member(object_id);
CREATE INDEX fkx_member__dest_member ON dest_member(member__id);



