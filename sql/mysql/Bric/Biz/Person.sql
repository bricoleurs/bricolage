-- Project: Bricolage
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@justatheory.com>

-- This DDL creates the basic table for all Bric::Person objects. The indexes are
-- suggestions.

-- 
-- TABLE: person 
--

CREATE TABLE person (
    id        INTEGER           NOT NULL AUTO_INCREMENT,
    prefix    VARCHAR(32),
    lname     VARCHAR(64),
    fname     VARCHAR(64),
    mname     VARCHAR(64),
    suffix    VARCHAR(32),
    active    BOOLEAN           NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_person__id PRIMARY KEY (id)
)
    ENGINE    InnoDB
    AUTO_INCREMENT 1024;



--
-- TABLE: person_member
--

CREATE TABLE person_member (
    id          INTEGER         NOT NULL  AUTO_INCREMENT,
    object_id   INTEGER         NOT NULL,
    member__id  INTEGER         NOT NULL,
    CONSTRAINT pk_person_member__id PRIMARY KEY (id)
)
    ENGINE    InnoDB
    AUTO_INCREMENT 1024;


-- 
-- INDEXES.
--

CREATE INDEX idx_person__lname ON person(lname(64));
CREATE INDEX idx_person__fname ON person(fname(64));
CREATE INDEX idx_person__mname ON person(mname(64));

CREATE INDEX fkx_person__person_member ON person_member(object_id);
CREATE INDEX fkx_member__person_member ON person_member(member__id);

--
-- AUTO_INCREMENT;
-- http://bugs.mysql.com/bug.php?id=21404
--

ALTER TABLE person AUTO_INCREMENT 1024;
ALTER TABLE person_member AUTO_INCREMENT 1024;
