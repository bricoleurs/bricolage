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

CREATE SEQUENCE seq_alert_type_rule START  1024;

-- 
-- TABLE: alert_type_rule
--

CREATE TABLE alert_type_rule(
    id                INTEGER         NOT NULL
                                      DEFAULT NEXTVAL('seq_alert_type_rule'),
    alert_type__id    INTEGER         NOT NULL,
    attr              VARCHAR(64)     NOT NULL,
    operator          CHAR(2)         NOT NULL,
    value             VARCHAR(256)    NOT NULL,
    CONSTRAINT pk_alert_type_rule__id PRIMARY KEY (id)
);

-- 
-- INDEXS.
--

CREATE INDEX idx_alert_type_rule__attr ON alert_type_rule(LOWER(attr));
CREATE INDEX idx_alert_type_rule__value ON alert_type_rule(LOWER(value));
CREATE INDEX fkx_alert_type__at_rule ON alert_type_rule(alert_type__id);



