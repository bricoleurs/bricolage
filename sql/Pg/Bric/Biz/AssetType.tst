-- -----------------------------------------------------------------------------
-- AssetType.tst
--
-- VERSION: $Revision: 1.2 $
--
-- Test values.
--

/*

DELETE FROM at_type           WHERE id IN (1, 2);
DELETE FROM grp               WHERE id IN (330, 340);
DELETE FROM member            WHERE id IN (330, 340);
DELETE FROM element        WHERE id IN (1, 2, 3, 4);
DELETE FROM element_member WHERE id IN (1, 2);

-- Create AT Types.

INSERT INTO at_type (id,name,description,top_level,paginated,
biz_class__id,active)
VALUES (1, 'Stories', 'Story Elements', 1, 0, 10, 1);

INSERT INTO at_type (id,name,description,top_level,paginated,
biz_class__id, active)
VALUES (2, 'General', 'General Use Elements', 0, 0, 10, 1);

-- Create groups

INSERT INTO grp (id,class__id,name,description) 
VALUES (330,24,'AssetType Group', 'Grouped containers');

INSERT INTO grp (id,class__id,name,description) 
VALUES (340,24,'AssetType Group', 'Grouped containers');

-- Create members

INSERT INTO member (id, grp__id, class__id, active) 
VALUES (330, 330, 22, 1);

INSERT INTO member (id, grp__id, class__id, active) 
VALUES (340, 340, 22, 1);

-- Create elements

INSERT INTO element (id,name,description,type__id,at_grp__id,primary_oc__id,active)
VALUES (1,'Column','column','A weekly column element',1,330,1,1);

INSERT INTO element__output_channel (id, element__id, output_channel__id, active)
VALUES (1, 1, 1, 1);

INSERT INTO element__output_channel (id, element__id, output_channel__id, active)
VALUES (2, 1, 2, 1);

INSERT INTO element__output_channel (id, element__id, output_channel__id, active)
VALUES (3, 1, 3, 1);

INSERT INTO element (id,name,description,type__id,at_grp__id,primary_oc__id,active)
VALUES (2,'Inset','inset','An inset element',2,340,NULL,1);

INSERT INTO element (id,name,description,type__id,primary_oc__id,active)
VALUES (3,'Pull Quote','pull_quote','A pull quote element',2,NULL,1);

INSERT INTO element (id,name,description,type__id,primary_oc__id,active)
VALUES (4,'Page','A page element.',2,NULL,1);

-- Create element_members

INSERT INTO element_member (id, object_id, member__id) 
VALUES (1,3,330);

INSERT INTO element_member (id, object_id,member__id) 
VALUES (2,4,340);

*/

