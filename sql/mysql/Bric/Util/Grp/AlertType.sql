-- Project: Bricolage
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@justatheory.com>
--

-- 
-- TABLE: alert_type_member 
--

CREATE TABLE alert_type_member (
    id          INTEGER        NOT NULL AUTO_INCREMENT,
    object_id   INTEGER        NOT NULL,
    member__id  INTEGER        NOT NULL,
    CONSTRAINT pk_alert_type_member__id PRIMARY KEY (id)
)
    ENGINE      InnoDB
    AUTO_INCREMENT 1024;

--
-- INDEXES.
--
CREATE INDEX fkx_alert_type__alert_type_member ON alert_type_member(object_id);
CREATE INDEX fkx_member__alert_type_member ON alert_type_member(member__id);

--
-- AUTO_INCREMENT;
-- http://bugs.mysql.com/bug.php?id=21404
--

ALTER TABLE alert_type_member AUTO_INCREMENT 1024;
