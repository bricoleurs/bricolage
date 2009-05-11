-- Project: Bricolage
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@justatheory.com>
--

-- 
-- TABLE: user_member 
--

CREATE TABLE user_member (
    id          INTEGER        NOT NULL AUTO_INCREMENT,
    object_id   INTEGER        NOT NULL,
    member__id  INTEGER        NOT NULL,
    CONSTRAINT pk_user_member__id PRIMARY KEY (id)
)
    ENGINE      InnoDB
    AUTO_INCREMENT 1024;

--
-- INDEXES.
--
CREATE INDEX fkx_user__user_member ON user_member(object_id);
CREATE INDEX fkx_member__user_member ON user_member(member__id);

--
-- AUTO_INCREMENT;
-- http://bugs.mysql.com/bug.php?id=21404
--

ALTER TABLE user_member AUTO_INCREMENT 1024;
