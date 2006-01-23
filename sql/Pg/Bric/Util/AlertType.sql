-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate$
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
    id                NUMERIC(10, 0)    NOT NULL
                                        DEFAULT NEXTVAL('seq_alert_type'),
    event_type__id    NUMERIC(10, 0)    NOT NULL,
    usr__id           NUMERIC(10, 0)    NOT NULL,
    name              VARCHAR(64)       NOT NULL,
    subject           VARCHAR(128),
    message           VARCHAR(512),
    active            NUMERIC(1, 0)     NOT NULL 
                                        CONSTRAINT ck_alert_type__active CHECK (active IN (1,0))
                                        DEFAULT 1,
    del               NUMERIC(1, 0)     NOT NULL 
                                        CONSTRAINT ck_alert_type__del CHECK (del IN (1,0))
                                        DEFAULT 0,
    CONSTRAINT pk_alert_type__id PRIMARY KEY (id)
);


-- 
-- TABLE: alert_type__grp__contact 
--

CREATE TABLE alert_type__grp__contact(
    alert_type__id    NUMERIC(10, 0)    NOT NULL,
    contact__id       NUMERIC(10, 0)    NOT NULL,
    grp__id           NUMERIC(10, 0)    NOT NULL,
    CONSTRAINT pk_alert_type__grp__contact PRIMARY KEY (alert_type__id, contact__id, grp__id)
);


-- 
-- TABLE: alert_type__usr__contact 
--

CREATE TABLE alert_type__usr__contact(
    alert_type__id    NUMERIC(10, 0)    NOT NULL,
    contact__id       NUMERIC(10, 0)    NOT NULL,
    usr__id           NUMERIC(10, 0)    NOT NULL,
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


