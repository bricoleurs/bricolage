-- Project: Bricolage
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Michael Soderstrom <miraso@pacbell.net>
--
-- The sql that will hold all the template asset information.

-- -----------------------------------------------------------------------------
-- Sequences

-- Unique ids for the template table
CREATE SEQUENCE seq_template START 1024;

CREATE SEQUENCE seq_template_instance START 1024;

-- Unique IDs for the story_member table
CREATE SEQUENCE seq_template_member START 1024;


-- -----------------------------------------------------------------------------
-- Table template
--
-- Description: The table that holds all the template info
--
--
CREATE TABLE template (
    id                  INTEGER        NOT NULL
                                       DEFAULT NEXTVAL('seq_template'),
    usr__id             INTEGER,  
    output_channel__id  INTEGER        NOT NULL,
    tplate_type         INT2           NOT NULL
                                       DEFAULT 1
                                       CONSTRAINT ck_template___tplate_type
                                         CHECK (tplate_type IN (1, 2, 3)),
    element_type__id    INTEGER,
    file_name           TEXT,
    current_version     INTEGER        NOT NULL,
    workflow__id        INTEGER        NOT NULL,
    desk__id            INTEGER        NOT NULL,
    published_version   INTEGER,
    deploy_status       BOOLEAN        NOT NULL DEFAULT FALSE,
    deploy_date         TIMESTAMP,
    active              BOOLEAN        NOT NULL DEFAULT TRUE,
    site__id            INTEGER        NOT NULL,
    CONSTRAINT pk_template__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table template_instance
--
-- Description:  An versioned instance of a template asset
--

CREATE TABLE template_instance (
    id              INTEGER        NOT NULL
                                   DEFAULT NEXTVAL('seq_template_instance'),
    name            VARCHAR(256),
    description     VARCHAR(1024),
    priority        INT2           NOT NULL
                                   DEFAULT 3
                                   CONSTRAINT ck_story__priority
                                   CHECK (priority BETWEEN 1 AND 5),
    template__id    INTEGER        NOT NULL,
    category__id    INTEGER,
    version         INTEGER,
    usr__id         INTEGER        NOT NULL,
    file_name       TEXT,
    data            TEXT,
    expire_date     TIMESTAMP,
    note            TEXT,
    checked_out     BOOLEAN        NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_template_instance__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table: template_member
-- 
-- Description: The link between template objects and member objects
--

CREATE TABLE template_member (
    id          INTEGER        NOT NULL
                               DEFAULT NEXTVAL('seq_template_member'),
    object_id   INTEGER        NOT NULL,
    member__id  INTEGER        NOT NULL,
    CONSTRAINT pk_template_member__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Indexes.
--

-- template.
CREATE UNIQUE INDEX udx_template__file_name__oc
       ON template(file_name, output_channel__id);
CREATE INDEX idx_template__file_name ON template(LOWER(file_name));
CREATE INDEX fkx_usr__template ON template(usr__id);
CREATE INDEX fkx_output_channel__template ON template(output_channel__id);
CREATE INDEX fkx_element_type__template ON template(element_type__id);
CREATE INDEX fkx_template__desk__id ON template(desk__id) WHERE desk__id > 0;
CREATE INDEX fkx_template__workflow__id ON template(workflow__id) WHERE workflow__id > 0;
CREATE INDEX fkx_site__template ON template(site__id);

-- template_instance.
CREATE INDEX idx_template_instance__name ON template_instance(LOWER(name));
CREATE INDEX fkx_usr__template_instance ON template_instance(usr__id);
CREATE INDEX fkx_template__tmpl_instance ON template_instance(template__id);
CREATE INDEX idx_template_instance__note ON template_instance(note) WHERE note IS NOT NULL;
CREATE INDEX fkx_template_instance_category ON template_instance(category__id);

-- template_member.
CREATE INDEX fkx_template__template_member ON template_member(object_id);
CREATE INDEX fkx_member__template_member ON template_member(member__id);
