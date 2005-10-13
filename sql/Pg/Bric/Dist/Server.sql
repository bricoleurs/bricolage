-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate$
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@wheeler.net>
--

-- 
-- Sequences.
--
CREATE SEQUENCE seq_server START 1024;

-- 
-- TABLE: server 
--
CREATE TABLE server(
    id                 NUMERIC(10, 0)   NOT NULL
                                        DEFAULT NEXTVAL('seq_server'),
    server_type__id    NUMERIC(10, 0)   NOT NULL,
    host_name          VARCHAR(128)     NOT NULL,
    os		       CHAR(5)		NOT NULL,
    doc_root           VARCHAR(128)     NOT NULL,
    login              VARCHAR(64),
    password           VARCHAR(64),
    cookie             VARCHAR(512),
    active             NUMERIC(1, 0)   NOT NULL
                                       DEFAULT 1
                                       CONSTRAINT ck_server__active
                                         CHECK (active IN (1,0)),
    CONSTRAINT pk_server__id PRIMARY KEY (id)
);


-- 
-- Indexes.
--
CREATE UNIQUE INDEX udx_server__name__st_id ON server(host_name, server_type__id);
CREATE INDEX fkx_server_type__server ON server(server_type__id);
CREATE INDEX idx_server__os ON server(os);


