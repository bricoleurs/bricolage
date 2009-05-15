-- Project: Bricolage
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@justatheory.com>
--

-- 
-- TABLE: alerted 
--

-- Note: The "NULL" specification for timestamp fields is Required to prevent
-- MySQL from helpfully adding "DEFAULT CURRENT_TIMESTAMP" or "DEFAULT
-- '0000-00-00 00:00:00'".

CREATE TABLE alerted (
    id           INTEGER           NOT NULL AUTO_INCREMENT,
    usr__id      INTEGER           NOT NULL,
    alert__id    INTEGER           NOT NULL,
    ack_time     TIMESTAMP         NULL DEFAULT NULL,
    CONSTRAINT pk_alerted__id PRIMARY KEY (id)
)
    ENGINE       InnoDB
    AUTO_INCREMENT 1024;


-- 
-- TABLE: alerted__contact_value 
--

CREATE TABLE alerted__contact_value(
    alerted__id                INTEGER         NOT NULL,
    contact__id             INTEGER         NOT NULL,
    contact_value__value    VARCHAR(256)    NOT NULL,
    sent_time               TIMESTAMP       NULL DEFAULT NULL,
    CONSTRAINT pk_alerted__contact_value PRIMARY KEY (alerted__id, contact__id, contact_value__value(254))
)
    ENGINE       InnoDB;

-- 
-- INDEXES.
--

-- alerted
CREATE INDEX idx_alerted__ack_time ON alerted(ack_time);
CREATE INDEX fkx_alert__alerted ON alerted(alert__id);
CREATE INDEX fkx_usr__alerted ON alerted(usr__id);

-- alerted__contact_value
CREATE INDEX idx_ac_value__sent_time ON alerted__contact_value(sent_time);
CREATE INDEX idx_ac_value__cv__value ON alerted__contact_value(contact_value__value);
CREATE INDEX fkx_alerted__alerted__contact ON alerted__contact_value(alerted__id);
CREATE INDEX fkx_contact__alerted__cont ON alerted__contact_value(contact__id);

--
-- AUTO_INCREMENT;
-- http://bugs.mysql.com/bug.php?id=21404
--

ALTER TABLE alerted AUTO_INCREMENT 1024;
