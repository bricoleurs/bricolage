-- Project: Bricolage
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@justatheory.com>
--

-- 
-- TABLE: org_member 
--

CREATE TABLE org_member (
    id          INTEGER        NOT NULL AUTO_INCREMENT,
    object_id   INTEGER        NOT NULL,
    member__id  INTEGER        NOT NULL,
    CONSTRAINT pk_org_member__id PRIMARY KEY (id)
)
    ENGINE      InnoDB
    AUTO_INCREMENT 1024;

--
-- INDEXES.
--
CREATE INDEX fkx_org__org_member ON org_member(object_id);
CREATE INDEX fkx_member__org_member ON org_member(member__id);

--
-- AUTO_INCREMENT;
-- http://bugs.mysql.com/bug.php?id=21404
--

ALTER TABLE org_member AUTO_INCREMENT 1024;
