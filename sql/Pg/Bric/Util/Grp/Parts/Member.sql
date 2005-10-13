-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate$
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Michael Soderstrom <miraso@pacbell.net>
--
-- -----------------------------------------------------------------------------
-- Member.sql
-- 
-- VERSION: $LastChangedRevision$
--
-- The member table and the tables that map member bac to their respective 
-- objects.   The member table contains an id and a group id.   The table that 
-- maps the object to its member contains an id an object id and a member id
--
-- Thought should be given to:
-- 		Ensuring that an object is not placed with in the same group twice
--		Making sure that an object that is deactivated from a group that is 
--			then put back in again will behave properly
--

-- -----------------------------------------------------------------------------

-- 
-- SEQUENCES.
--
CREATE SEQUENCE seq_member START  1024;
CREATE SEQUENCE seq_story_member START 1024;

-- -----------------------------------------------------------------------------
-- Table: member
--
-- Description:	The table that creates a member of a group.   The obj_member 
-- table then links the objects to the member table
--

CREATE TABLE member (
    id         NUMERIC(10,0)  NOT NULL
                              DEFAULT NEXTVAL('seq_member'),
    grp__id    NUMERIC(10,0)  NOT NULL,
    class__id  NUMERIC(10,0)  NOT NULL,
    active     NUMERIC(1,0)   NOT NULL
                              DEFAULT 1
                              CONSTRAINT ck_member__active
                                CHECK (active IN (0,1)),
    CONSTRAINT pk_member__id PRIMARY KEY (id)
);


--
-- INDEXES.
--
CREATE INDEX fkx_grp__member ON member(grp__id);
CREATE INDEX fkx_grp__class ON member(class__id);

-- Use the below section as an example to create new member tables for
-- other objects.
-- -----------------------------------------------------------------------------
-- Table: story_member
-- 
-- Description: The link between story objects and member objects
--

CREATE TABLE story_member (
    id          NUMERIC(10,0)  NOT NULL
                               DEFAULT NEXTVAL('seq_story_member'),
    object_id   NUMERIC(10,0)  NOT NULL,
    member__id  NUMERIC(10,0)  NOT NULL,
    CONSTRAINT pk_story_member__id PRIMARY KEY (id)
);

--
-- INDEXES.
--
CREATE INDEX fkx_story__story_member ON story_member(object_id);
CREATE INDEX fkx_member__story_member ON story_member(member__id);



