-- -----------------------------------------------------------------------------
-- Attribute.tst
--
-- VERSION: $Revision: 1.1 $
--

/*

-- -----------------------------------------------------------------------------
-- Table: attr_person

INSERT INTO attr_person (id,subsys,name,sql_type,active) 
VALUES ('1027','electrical','blinky light','short','1');

INSERT INTO attr_person (id,subsys,name,sql_type,active) 
VALUES ('1031','electrical','button','short','1');

INSERT INTO attr_person (id,subsys,name,sql_type,active) 
VALUES ('1032','electrical','rules','blob','1');

-- -----------------------------------------------------------------------------
-- Table: attr_person_val

INSERT INTO attr_person_val (id,object__id,attr__id,short_val,serial,active)
VALUES ('1024','1','1027','amber','0','1');

INSERT INTO attr_person_val (id,object__id,attr__id,short_val,serial,active)
VALUES ('1025','1','1031','depressed','0','1');

INSERT INTO attr_person_val (id,object__id,attr__id,blob_val,serial,active)
VALUES ('1026','1','1032','32866',0,'1');

-- -----------------------------------------------------------------------------
-- Table: attr_person_meta

INSERT INTO attr_person_meta (id,attr__id,name,value,active)
VALUES ('1024','1027','sound','klaxon','1');

INSERT INTO attr_person_meta (id,attr__id,name,value,active)
VALUES ('1025','1027','rate','furious','1');

INSERT INTO attr_person_meta (id,attr__id,name,value,active)
VALUES ('1026','1031','size','large','1');

*/