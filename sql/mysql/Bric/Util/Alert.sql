-- Project: Bricolage
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@justatheory.com>
--

-- 
-- TABLE: alert 
--

CREATE TABLE alert(
    id                INTEGER           NOT NULL AUTO_INCREMENT,
    alert_type__id    INTEGER           NOT NULL,
    event__id         INTEGER           NOT NULL,
    subject           VARCHAR(128),
    message           VARCHAR(512),
    timestamp         TIMESTAMP         NOT NULL
                                        DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_alert__id PRIMARY KEY (id)
)
    ENGINE            InnoDB
    AUTO_INCREMENT    1024;

-- 
-- INDEXES.
--
 
CREATE INDEX idx_alert__timestamp ON alert(timestamp);
CREATE INDEX fkx_alert_type__alert ON alert(alert_type__id);
CREATE INDEX fkx_event__alert ON alert(event__id);

--
-- AUTO_INCREMENT;
-- http://bugs.mysql.com/bug.php?id=21404
--

ALTER TABLE alert AUTO_INCREMENT 1024;
