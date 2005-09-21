-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate$
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Michael Soderstrom <miraso@pacbell.net>
--
-- The sql that will hold all the formatting asset information.
-- This replaces the Data, Container, Decorative Tables which 
-- were archectited away.

-- -----------------------------------------------------------------------------
-- Sequences

-- Unique ids for the formatting table
CREATE SEQUENCE seq_formatting START 1024;

CREATE SEQUENCE seq_formatting_instance START 1024;

-- Unique IDs for the story_member table
CREATE SEQUENCE seq_formatting_member START 1024;


-- -----------------------------------------------------------------------------
-- Table formatting
--
-- Description: The table that holds all the formatting info
--
--
CREATE TABLE formatting (
    id                  INTEGER        NOT NULL
                                       DEFAULT NEXTVAL('seq_formatting'),
    name                VARCHAR(256),
    description         VARCHAR(1024),
    priority            INT2           NOT NULL
                                       DEFAULT 3
                                       CONSTRAINT ck_story__priority
                                         CHECK (priority BETWEEN 1 AND 5),
    usr__id             INTEGER,  
    output_channel__id  INTEGER        NOT NULL,
    tplate_type         INT2           NOT NULL
                                       DEFAULT 1
                                       CONSTRAINT ck_formatting___tplate_type
                                         CHECK (tplate_type IN (1, 2, 3)),
    element_type__id    INTEGER,
    category__id        INTEGER,
    file_name           TEXT,
    current_version     INTEGER        NOT NULL,
    workflow__id        INTEGER        NOT NULL,
    desk__id            INTEGER        NOT NULL,
    published_version   INTEGER,
    deploy_status       BOOLEAN        NOT NULL DEFAULT FALSE,
    deploy_date         TIMESTAMP,
    expire_date         TIMESTAMP,
    active              BOOLEAN        NOT NULL DEFAULT TRUE,
    site__id            INTEGER        NOT NULL,
    CONSTRAINT pk_formatting__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table formatting_instance
--
-- Description:  An versioned instance of a formatting asset
--

CREATE TABLE formatting_instance (
    id              INTEGER        NOT NULL
                                       DEFAULT NEXTVAL('seq_formatting_instance'),
    formatting__id  INTEGER        NOT NULL,
    version         INTEGER,
    usr__id         INTEGER        NOT NULL,
    file_name       TEXT,
    data            TEXT,
    note            TEXT,
    checked_out     BOOLEAN        NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_formatting_instance__id PRIMARY KEY (id)
);
        

-- -----------------------------------------------------------------------------
-- Table: formatting_member
-- 
-- Description: The link between template objects and member objects
--

CREATE TABLE formatting_member (
    id          INTEGER        NOT NULL
                               DEFAULT NEXTVAL('seq_formatting_member'),
    object_id   INTEGER        NOT NULL,
    member__id  INTEGER        NOT NULL,
    CONSTRAINT pk_formatting_member__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Indexes.
--

-- formatting.
CREATE UNIQUE INDEX udx_formatting__file_name__oc
       ON formatting(file_name, output_channel__id);
CREATE INDEX idx_formatting__name ON formatting(LOWER(name));
CREATE INDEX idx_formatting__file_name ON formatting(LOWER(file_name));
CREATE INDEX idx_formatting__description ON formatting(LOWER(description));
CREATE INDEX idx_formatting__deploy_date ON formatting(deploy_date);
CREATE INDEX fkx_usr__formatting ON formatting(usr__id);
CREATE INDEX fkx_output_channel__formatting ON formatting(output_channel__id);
CREATE INDEX fkx_element_type__formatting ON formatting(element_type__id);
CREATE INDEX fkx_category__formatting ON formatting(category__id);
CREATE INDEX fdx_formatting__desk__id ON formatting(desk__id) WHERE desk__id > 0;
CREATE INDEX fdx_formatting__workflow__id ON formatting(workflow__id) WHERE workflow__id > 0;
CREATE INDEX fkx_site__formatting ON formatting(site__id);

-- formatting_instance.
CREATE INDEX fkx_usr__formatting_instance ON formatting_instance(usr__id);
CREATE INDEX fkx_formatting__frmt_instance ON formatting_instance(formatting__id);
CREATE INDEX idx_formatting_instance__note ON formatting_instance(note) WHERE note IS NOT NULL;

-- formatting_member.
CREATE INDEX fkx_frmt__frmt_member ON formatting_member(object_id);
CREATE INDEX fkx_member__frmt_member ON formatting_member(member__id);
