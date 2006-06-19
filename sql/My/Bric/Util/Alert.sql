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

CREATE SEQUENCE seq_alert START 1024;


-- 
-- TABLE: alert 
--

CREATE TABLE alert(
    id                INTEGER           NOT NULL
                                        DEFAULT NEXTVAL('seq_alert'),
    alert_type__id    INTEGER           NOT NULL,
    event__id         INTEGER           NOT NULL,
    subject           VARCHAR(128),
    message           VARCHAR(512),
    timestamp         TIMESTAMP         NOT NULL
                                        DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_alert__id PRIMARY KEY (id)
);

-- 
-- INDEXES.
--
 
CREATE INDEX idx_alert__timestamp ON alert(timestamp);
CREATE INDEX fkx_alert_type__alert ON alert(alert_type__id);
CREATE INDEX fkx_event__alert ON alert(event__id);


