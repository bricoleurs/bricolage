-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate: 2006-03-18 03:10:10 +0200 (Sat, 18 Mar 2006) $
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@justatheory.com>
--

-- 
-- TABLE: server 
--
CREATE TABLE server(
    id                 INTEGER          NOT NULL AUTO_INCREMENT,
    server_type__id    INTEGER          NOT NULL,
    host_name          VARCHAR(128)     NOT NULL,
    os		           CHAR(5)		    NOT NULL,
    doc_root           VARCHAR(128)     NOT NULL,
    login              VARCHAR(64),
    password           VARCHAR(64),
    cookie             VARCHAR(512),
    active             BOOLEAN          NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_server__id PRIMARY KEY (id)
)
    ENGINE             InnoDB
    AUTO_INCREMENT     1024;


-- 
-- Indexes.
--
CREATE UNIQUE INDEX udx_server__name__st_id ON server(host_name(128), server_type__id);
CREATE INDEX fkx_server_type__server ON server(server_type__id);
CREATE INDEX idx_server__os ON server(os);


