-- Project: Bricolage
-- VERSION: $Revision: 1.1 $
--
-- $Date: 2001-09-06 21:54:34 $
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@wheeler.net>
--

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
-- Sequences.
--
CREATE SEQUENCE seq_server START 1024;

-- 
-- Indexes.
--
CREATE UNIQUE INDEX udx_server__name__st_id ON server(host_name, server_type__id);
CREATE INDEX fkx_server_type__server ON server(server_type__id);
CREATE INDEX idx_server__os ON server(os);

/*
Change Log:
$Log: Server.sql,v $
Revision 1.1  2001-09-06 21:54:34  wheeler
Initial revision

*/
