-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@justatheory.com>

-- This DDL creates the basic table for all Bric::Site objects. The indexes are
-- suggestions.

-- 
-- SEQUENCES.
--

CREATE SEQUENCE seq_site_member START 1024;


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
);



--
-- TABLE: site_member
--

CREATE TABLE site_member (
    id          INTEGER  NOT NULL
                         DEFAULT NEXTVAL('seq_site_member'),
    object_id   INTEGER  NOT NULL,
    member__id  INTEGER  NOT NULL,
    CONSTRAINT pk_site_member__id PRIMARY KEY (id)
);


-- 
-- INDEXES.
--

CREATE UNIQUE INDEX udx_site__name ON site(LOWER(name));
CREATE UNIQUE INDEX udx_site__domain_name ON site(LOWER(domain_name));
CREATE INDEX fkx_site__site_member ON site_member(object_id);
CREATE INDEX fkx_member__site_member ON site_member(member__id);
