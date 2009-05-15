-- Project: Bricolage
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@justatheory.com>

-- This DDL creates the basic table for all Bric::Site objects. The indexes are
-- suggestions.

-- 
-- TABLE: site 
--

CREATE TABLE site (
    id          INTEGER         NOT NULL,
    name        TEXT,
    description TEXT,
    domain_name TEXT,
    active      BOOLEAN         NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_site__id PRIMARY KEY (id)
)
    ENGINE      InnoDB;



--
-- TABLE: site_member
--

CREATE TABLE site_member (
    id          INTEGER  NOT NULL AUTO_INCREMENT,
    object_id   INTEGER  NOT NULL,
    member__id  INTEGER  NOT NULL,
    CONSTRAINT pk_site_member__id PRIMARY KEY (id)
)
    ENGINE      InnoDB
    AUTO_INCREMENT 1024;


-- 
-- INDEXES.
--

CREATE UNIQUE INDEX udx_site__name ON site(name(254));
CREATE UNIQUE INDEX udx_site__domain_name ON site(domain_name(254));
CREATE INDEX fkx_site__site_member ON site_member(object_id);
CREATE INDEX fkx_member__site_member ON site_member(member__id);

--
-- AUTO_INCREMENT;
-- http://bugs.mysql.com/bug.php?id=21404
--

ALTER TABLE site_member AUTO_INCREMENT 1024;
