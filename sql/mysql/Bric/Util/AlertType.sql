-- Project: Bricolage
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@justatheory.com>
--

-- 
-- TABLE: alert_type 
--

CREATE TABLE alert_type (
    id                INTEGER           NOT NULL AUTO_INCREMENT,
    event_type__id    INTEGER           NOT NULL,
    usr__id           INTEGER           NOT NULL,
    name              VARCHAR(64)       NOT NULL,
    subject           VARCHAR(128),
    message           VARCHAR(512),
    active            BOOLEAN           NOT NULL DEFAULT TRUE,
    del               BOOLEAN           NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_alert_type__id PRIMARY KEY (id)
)
    ENGINE            InnoDB
    AUTO_INCREMENT    1024;


-- 
-- TABLE: alert_type__grp__contact 
--

CREATE TABLE alert_type__grp__contact(
    alert_type__id    INTEGER           NOT NULL,
    contact__id       INTEGER           NOT NULL,
    grp__id           INTEGER           NOT NULL,
    CONSTRAINT pk_alert_type__grp__contact PRIMARY KEY (alert_type__id, contact__id, grp__id)
)
    ENGINE            InnoDB;


-- 
-- TABLE: alert_type__usr__contact 
--

CREATE TABLE alert_type__usr__contact(
    alert_type__id    INTEGER           NOT NULL,
    contact__id       INTEGER           NOT NULL,
    usr__id           INTEGER           NOT NULL,
    CONSTRAINT pk_alert_type__usr__contact PRIMARY KEY (alert_type__id, usr__id, contact__id)
)
    ENGINE            InnoDB;


-- 
-- INDEXES.
--

-- alert_type
CREATE UNIQUE INDEX udx_alert_type__name__usr__id
ON alert_type(name(64), usr__id);

CREATE INDEX idx_alert_type__name ON alert_type(name(64));
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

--
-- AUTO_INCREMENT;
-- http://bugs.mysql.com/bug.php?id=21404
--

ALTER TABLE alert_type AUTO_INCREMENT 1024;
