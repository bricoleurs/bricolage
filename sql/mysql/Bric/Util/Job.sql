-- Project: Bricolage
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@justatheory.com>
--

-- 
-- TABLE: job 
--

CREATE TABLE job (
    id                 INTEGER           NOT NULL AUTO_INCREMENT,
    name               TEXT              NOT NULL,
    usr__id            INTEGER           NOT NULL,
    sched_time         TIMESTAMP         NOT NULL
                                         DEFAULT CURRENT_TIMESTAMP,
    priority           INT2              NOT NULL 
                                         DEFAULT 3
                                           CHECK (priority BETWEEN 1 AND 5),
    comp_time          TIMESTAMP         NULL DEFAULT NULL,
    expire             BOOLEAN           NOT NULL DEFAULT FALSE,
    failed             BOOLEAN           NOT NULL DEFAULT FALSE,
    tries              INT2              NOT NULL DEFAULT 0
                                           CHECK (tries BETWEEN 0 AND 10),
    executing          BOOLEAN           NOT NULL DEFAULT FALSE,
    class__id          INTEGER           NOT NULL,
    story_instance__id INTEGER,
    media_instance__id INTEGER,
    error_message TEXT,
    CONSTRAINT pk_job__id PRIMARY KEY (id)
)
    ENGINE             InnoDB
    AUTO_INCREMENT     1024;


-- 
-- TABLE: job__resource 
--

CREATE TABLE job__resource(
    job__id         INTEGER           NOT NULL,
    resource__id    INTEGER           NOT NULL,
    CONSTRAINT pk_job__resource PRIMARY KEY (job__id,resource__id)
)
    ENGINE             InnoDB;


-- 
-- TABLE: job__server_type 
--

CREATE TABLE job__server_type(
    job__id             INTEGER        NOT NULL,
    server_type__id     INTEGER        NOT NULL,
    CONSTRAINT pk_job__server_type PRIMARY KEY (job__id,server_type__id)
)
    ENGINE             InnoDB;

--
-- TABLE: job_member
--

CREATE TABLE job_member (
    id          INTEGER        NOT NULL AUTO_INCREMENT,
    object_id   INTEGER        NOT NULL,
    member__id  INTEGER        NOT NULL,
    CONSTRAINT pk_job_member__id PRIMARY KEY (id)
)
    ENGINE             InnoDB
    AUTO_INCREMENT     1024;


-- 
-- INDEXES. 
--
CREATE INDEX idx_job__name ON job(name(254));
CREATE INDEX idx_job__sched_time ON job(sched_time);
CREATE INDEX idx_job__comp_time__is_null ON job(comp_time);
CREATE INDEX idx_job__comp_time ON job(comp_time);
CREATE INDEX idx_job__executing ON job(executing);

CREATE INDEX fkx_story_instance__job ON job(story_instance__id);
CREATE INDEX fkx_media_instance__job ON job(media_instance__id);

CREATE INDEX fkx_job__job__resource ON job__resource(job__id);
CREATE INDEX fkx_usr__job ON job (usr__id);
CREATE INDEX fkx_resource__job__resource ON job__resource(resource__id);
CREATE INDEX fkx_job__job__server_type ON job__server_type(job__id);
CREATE INDEX fkx_srvr_type__job__srvr_type ON job__server_type(server_type__id);

CREATE INDEX fkx_job__job_member ON job_member(object_id);
CREATE INDEX fkx_member__job_member ON job_member(member__id);

--
-- AUTO_INCREMENT;
-- http://bugs.mysql.com/bug.php?id=21404
--

ALTER TABLE job AUTO_INCREMENT 1024;
ALTER TABLE job_member AUTO_INCREMENT 1024;
