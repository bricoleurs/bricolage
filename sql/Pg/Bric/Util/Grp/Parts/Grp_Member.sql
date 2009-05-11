-- Project: Bricolage
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Michael Soderstrom <miraso@pacbell.net>
--
-- -----------------------------------------------------------------------------
-- Member.sql
-- 
--
-- The member table and the tables that map member back to their respective 
-- objects. The member table contains an id and a group id. The table that 
-- maps the object to its member contains an id an object id and a member id
--
-- Thought should be given to:
--         Ensuring that an object is not placed with in the same group twice
--        Making sure that an object that is deactivated from a group that is 
--            then put back in again will behave properly
--

-- -----------------------------------------------------------------------------
-- Sequences


-- Unique IDs for the grp_member table
CREATE SEQUENCE seq_grp_member START  1024;


-- -----------------------------------------------------------------------------
-- Table: grp_member
-- 
-- Description: The link between stroy objects and member objects
--

CREATE TABLE grp_member (
    id            INTEGER         NOT NULL
                                  DEFAULT NEXTVAL('seq_grp_member'),
    object_id     INTEGER         NOT NULL,
    member__id    INTEGER            NOT NULL,
    CONSTRAINT pk_grp_member__id PRIMARY KEY (id)
);


--
-- INDEXES
--

CREATE INDEX fkx_grp__grp_member ON grp_member(object_id);
CREATE INDEX fkx_member__grp_member ON grp_member(member__id);



