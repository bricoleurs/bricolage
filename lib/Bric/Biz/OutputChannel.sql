-- Project: Bricolage
-- VERSION: $Revision: 1.2.2.1 $
--
-- $Date: 2001-10-09 21:51:06 $
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Michael Soderstrom <miraso@pacbell.net>
--
-- Description: The table that holds the registered Output Channels.
--				This maps to the Bric::OutputChannel Class.
--
--

-- -----------------------------------------------------------------------------
-- Sequences

-- Unique IDs for the output_channel table
CREATE SEQUENCE seq_output_channel START 1024;
CREATE SEQUENCE seq_output_channel_member START 1024;

-- -----------------------------------------------------------------------------
-- Table output_channel
--
-- Description: Holds info on the various output channels and is referenced
-- 				by the formatting assets and elements
--
--

CREATE TABLE output_channel (
    id	         NUMERIC(10,0)  NOT NULL
                                DEFAULT NEXTVAL('seq_output_channel'),
    name         VARCHAR(64)    NOT NULL,
    description  VARCHAR(256),
    pre_path     VARCHAR(64),
    post_path    VARCHAR(64),
    filename     VARCHAR(32)    NOT NULL,
    file_ext     VARCHAR(32),
    primary_ce   NUMERIC(1,0),
    active       NUMERIC(1,0)   NOT NULL
                                DEFAULT 1
                                CONSTRAINT ck_output_channel__active
                                  CHECK (active IN (0,1)),
    CONSTRAINT pk_output_channel__id PRIMARY KEY (id)
);

--
-- TABLE: output_channel_member
--

CREATE TABLE output_channel_member (
    id          NUMERIC(10,0)  NOT NULL
                               DEFAULT NEXTVAL('seq_output_channel_member'),
    object_id   NUMERIC(10,0)  NOT NULL,
    member__id  NUMERIC(10,0)  NOT NULL,
    CONSTRAINT pk_output_channel_member__id PRIMARY KEY (id)
);

-- 
-- INDEXES.
--
CREATE UNIQUE INDEX udx_output_channel__name ON output_channel(LOWER(name));
CREATE INDEX idx_output_channel__filename ON output_channel(LOWER(filename));
CREATE INDEX idx_output_channel__file_ext ON output_channel(LOWER(file_ext));
CREATE INDEX fkx_output_channel__oc_member ON output_channel_member(object_id);
CREATE INDEX fkx_member__oc_member ON output_channel_member(member__id);

