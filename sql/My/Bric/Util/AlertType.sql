-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate: 2006-03-18 03:10:10 +0200 (Sat, 18 Mar 2006) $
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@justatheory.com>
--

-- 
-- SEQUENCES.
--

CREATE SEQUENCE seq_alert_type START 1024;


-- 
-- TABLE: alert_type 
--

CREATE TABLE alert_type (
    id                INTEGER           NOT NULL
                                        DEFAULT NEXTVAL('seq_alert_type'),
    event_type__id    INTEGER           NOT NULL,
    usr__id           INTEGER           NOT NULL,
    name              VARCHAR(64)       NOT NULL,
    subject           VARCHAR(128),
    message           VARCHAR(512),
    active            BOOLEAN           NOT NULL DEFAULT TRUE,
    del               BOOLEAN           NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_alert_type__id PRIMARY KEY (id)
);


-- 
-- TABLE: alert_type__grp__contact 
--

CREATE TABLE alert_type__grp__contact(
    alert_type__id    INTEGER           NOT NULL,
    contact__id       INTEGER           NOT NULL,
    grp__id           INTEGER           NOT NULL,
    CONSTRAINT pk_alert_type__grp__contact PRIMARY KEY (alert_type__id, contact__id, grp__id)
);


-- 
-- TABLE: alert_type__usr__contact 
--

CREATE TABLE alert_type__usr__contact(
    alert_type__id    INTEGER           NOT NULL,
    contact__id       INTEGER           NOT NULL,
    usr__id           INTEGER           NOT NULL,
    CONSTRAINT pk_alert_type__usr__contact PRIMARY KEY (alert_type__id, usr__id, contact__id)
);


-- 
-- INDEXES.
--

-- alert_type
CREATE UNIQUE INDEX udx_alert_type__name__usr__id
ON alert_type(lower_text_num(name, usr__id));

CREATE INDEX idx_alert_type__name ON alert_type(LOWER(name));
CREATE INDEX fkx_event_type__alert_type ON alert_type(event_type__id);
CREATE INDEX fkx_usr__alert_type ON alert_type(usr__id);

-- alert_type__grp__contact
CREATE INDEX fkx_alert_type__grp__contact ON alert_type__grp__contact(alert_type__id);
CREATE INDEX fkx_contact__grp__contact ON alert_type__grp__contact(contact__id);
CREATE INDEX fkx_grp__grp__contact ON alert_type__grp__contact(grp__id);

-- alert_type__usr__contact
CREATE INDEX fkx_alert_type__at_user__cont ON alert_type__usr__contact(alert_type__id);
CREATE INDEX fkx_contact__at_usr__contact  ON alert_type__usr__contact(contact__id);
CREATE INDEX fkx_usr__at_usr__contact ON alert_type__usr__contact(usr__id);


