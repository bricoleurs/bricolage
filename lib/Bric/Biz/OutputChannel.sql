-- Project: Bricolage
-- VERSION: $Revision: 1.2 $
--
-- $Date: 2001-09-27 15:41:46 $
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

/*
Change Log:
$Log: OutputChannel.sql,v $
Revision 1.2  2001-09-27 15:41:46  wheeler
Added filename and file_ext columns to OutputChannel API. Also added a
configuration directive to CE::Config to specify the default filename and
extension for the system. Will need to document later that these can be set, or
move them into preferences. Will also need to use the filename and file_ext
properties of Bric::Biz::OutputChannel in the Burn System.

Revision 1.1.1.1  2001/09/06 21:53:28  wheeler
Upload to SourceForge.

*/