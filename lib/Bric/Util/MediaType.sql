-- Project: Bricolage
-- VERSION: $Revision: 1.3 $
--
-- $Date: 2001-10-11 00:34:54 $
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@wheeler.net>
--

--
-- SEQUENCES.
--
CREATE SEQUENCE seq_media_type START 1024;
CREATE SEQUENCE seq_media_type_ext START 1024;

-- 
-- TABLE: media_type 
--

CREATE TABLE media_type (
    id             NUMERIC(10, 0)    NOT NULL
                                     DEFAULT NEXTVAL('seq_media_type'),
    name           VARCHAR(128)      NOT NULL,
    description    VARCHAR(256),
    active         NUMERIC(1, 0)     NOT NULL
                                     DEFAULT 1
                                     CONSTRAINT ck_media_type__active
                                       CHECK (active IN (1,0)),
    CONSTRAINT pk_media_type__id PRIMARY KEY (id)
);


-- 
-- TABLE: media_type_ext
--

CREATE TABLE media_type_ext (
    id                  NUMERIC(10, 0)    NOT NULL
                                          DEFAULT NEXTVAL('seq_media_type_ext'),
    media_type__id      NUMERIC(10, 0)    NOT NULL,
    extension           VARCHAR(10)       NOT NULL,
    CONSTRAINT pk_media_type_ext__id PRIMARY KEY (id)
);


-- 
-- INDEXES. 
--

CREATE UNIQUE INDEX udx_media_type__name ON media_type(LOWER(name));
CREATE UNIQUE INDEX udx_media_type_ext__extension ON media_type(LOWER(name));
CREATE INDEX fkx_media_type__media_type_ext ON media_type_ext(media_type__id);


