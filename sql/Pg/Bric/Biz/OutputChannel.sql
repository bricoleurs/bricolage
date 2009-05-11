-- Project: Bricolage
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Michael Soderstrom <miraso@pacbell.net>
--
-- Description: The table that holds the registered Output Channels.
--                This maps to the Bric::OutputChannel Class.
--
--

-- -----------------------------------------------------------------------------
-- Sequences

-- Unique IDs for the output_channel table
CREATE SEQUENCE seq_output_channel START 1024;
CREATE SEQUENCE seq_output_channel_include START 1024;
CREATE SEQUENCE seq_output_channel_member START 1024;

-- -----------------------------------------------------------------------------
-- Table output_channel
--
-- Description: Holds info on the various output channels and is referenced
--                 by templates and elements
--
--

CREATE TABLE output_channel (
    id             INTEGER            NOT NULL
                                    DEFAULT NEXTVAL('seq_output_channel'),
    name             VARCHAR(64)    NOT NULL,
    description      VARCHAR(256),
    site__id         INTEGER        NOT NULL,
    protocol         VARCHAR(16),
    filename         VARCHAR(32)    NOT NULL,
    file_ext         VARCHAR(32),
    primary_ce       BOOLEAN,
    uri_format       VARCHAR(64)    NOT NULL,
    fixed_uri_format VARCHAR(64)    NOT NULL,
    uri_case         INT2           NOT NULL DEFAULT 1
                                     CONSTRAINT ck_output_channel__uri_case
                                     CHECK (uri_case IN (1,2,3)),
    use_slug         BOOLEAN        NOT NULL DEFAULT FALSE,
    burner           INT2           NOT NULL DEFAULT 1,
    active           BOOLEAN        NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_output_channel__id PRIMARY KEY (id)
);


--
-- TABLE: output_channel_include
--

CREATE TABLE output_channel_include (
    id                         INTEGER  NOT NULL
                               DEFAULT NEXTVAL('seq_output_channel_include'),
    output_channel__id         INTEGER  NOT NULL,
    include_oc_id              INTEGER  NOT NULL
                               CONSTRAINT ck_oc_include__include_oc_id
                                 CHECK (include_oc_id <> output_channel__id),
    CONSTRAINT pk_output_channel_include__id PRIMARY KEY (id)
);

--
-- TABLE: output_channel_member
--

CREATE TABLE output_channel_member (
    id          INTEGER  NOT NULL
                         DEFAULT NEXTVAL('seq_output_channel_member'),
    object_id   INTEGER  NOT NULL,
    member__id  INTEGER  NOT NULL,
    CONSTRAINT pk_output_channel_member__id PRIMARY KEY (id)
);

-- 
-- INDEXES.
--
CREATE UNIQUE INDEX udx_output_channel__name_site
ON output_channel(lower_text_num(name, site__id));

CREATE INDEX fkx_site__output_channel ON output_channel(site__id);
CREATE INDEX idx_output_channel__filename ON output_channel(LOWER(filename));
CREATE INDEX idx_output_channel__file_ext ON output_channel(LOWER(file_ext));

CREATE INDEX fkx_output_channel__oc_include ON output_channel_include(output_channel__id);
CREATE INDEX fkx_oc__oc_include_inc ON output_channel_include(include_oc_id);
CREATE UNIQUE INDEX udx_output_channel_include ON output_channel_include(output_channel__id, include_oc_id);
CREATE INDEX fkx_output_channel__oc_member ON output_channel_member(object_id);
CREATE INDEX fkx_member__oc_member ON output_channel_member(member__id);

