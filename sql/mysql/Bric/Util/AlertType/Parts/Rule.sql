-- Project: Bricolage
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@justatheory.com>
--

-- 
-- TABLE: alert_type_rule
--

CREATE TABLE alert_type_rule(
    id                INTEGER         NOT NULL AUTO_INCREMENT,
    alert_type__id    INTEGER         NOT NULL,
    attr              VARCHAR(64)     NOT NULL,
    operator          CHAR(2)         NOT NULL,
    value             VARCHAR(256)    NOT NULL,
    CONSTRAINT pk_alert_type_rule__id PRIMARY KEY (id)
)
    ENGINE            InnoDB
    AUTO_INCREMENT    1024;

-- 
-- INDEXS.
--

CREATE INDEX idx_alert_type_rule__attr ON alert_type_rule(attr(64));
CREATE INDEX idx_alert_type_rule__value ON alert_type_rule(value(254));
CREATE INDEX fkx_alert_type__at_rule ON alert_type_rule(alert_type__id);

--
-- AUTO_INCREMENT;
-- http://bugs.mysql.com/bug.php?id=21404
--

ALTER TABLE alert_type_rule AUTO_INCREMENT 1024;
