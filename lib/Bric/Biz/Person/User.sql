-- Project: Bricolage
-- VERSION: $Revision: 1.1 $
--
-- $Date: 2001-09-06 21:54:14 $
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@wheeler.net>

-- This DDL creates the basic table for Bric::Person::Usr objects, and
-- establishes its relationship with Bric::Person. The login field must be unique,
-- hence the udx_usr__login index.


-- 
-- TABLE: usr 
--

CREATE TABLE usr (
    id           NUMERIC(10, 0)    NOT NULL,
    login        VARCHAR(128)      NOT NULL,
    password     CHAR(32)          NOT NULL,
    active       NUMERIC(1, 0)     NOT NULL 
                                   DEFAULT 1
                                   CONSTRAINT ck_usr__active
                                     CHECK (active IN (1,0)),
    CONSTRAINT pk_usr__id PRIMARY KEY (id)
);

--
-- FUNCTION: login_avil
--
-- This function is used by the table constraint ck_usr__login below to
-- determine whether the login can be used. The rule is that there can be any
-- number of rows with the same login, but only one of them can be active. This
-- allows for the same login name to be recycled for new users, but only one
-- active user can use it at a time.

CREATE   FUNCTION login_avail(varchar, numeric(1,0), numeric(10, 0))
         RETURNS BOOLEAN
AS       'SELECT CASE WHEN
                      (SELECT 1
                       FROM   usr
                       WHERE  $2 = 1
                              AND id <> $3
                              AND LOWER(login) = $1
                              AND active = 1) > 0
                 THEN false ELSE true END'
LANGUAGE 'sql'
WITH     (isstrict);

-- Now apply the constraint to the login column of the usr table.

ALTER TABLE usr ADD CONSTRAINT ck_usr__login
  CHECK (login_avail(LOWER(login), active, id));



-- 
-- INDEXES.
--
CREATE INDEX idx_usr__login ON usr(LOWER(login));


/*
Change Log:
$Log: User.sql,v $
Revision 1.1  2001-09-06 21:54:14  wheeler
Initial revision

*/