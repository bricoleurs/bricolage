-- -----------------------------------------------------------------------------
-- Catergory.val
--
-- VERSION: $Revision: 1.1 $
--
-- Test values.
--

DELETE FROM category        WHERE id IN (1, 2, 3, 4);
DELETE FROM grp             WHERE id IN (701, 702, 703, 704);
DELETE FROM member          WHERE id IN (702, 703, 704);
DELETE FROM category_member WHERE id IN (702, 703, 704);

-- -----------------------------------------------------------------------------
-- Science

INSERT INTO category (id,directory,category_grp_id) 
VALUES (1, 'science', 701);

INSERT INTO grp (id,class__id,name,description,secret)
VALUES (701, 23, 'Science', 'All things sciencey', 1);

-- -----------------------------------------------------------------------------
-- Material

INSERT INTO category (id,directory,category_grp_id) 
VALUES (2, 'material', 702);

INSERT INTO grp (id,class__id,name,description,parent_id,secret)
VALUES (702, 23, 'Material', 'The study of new materials', 701, 1);

INSERT INTO member (id,grp__id, class__id, active) 
VALUES (702, 701, 20, 1);

INSERT INTO category_member (id, object_id, member__id)
VALUES (702, 2, 702);

-- -----------------------------------------------------------------------------
-- Physical

INSERT INTO category (id,directory,category_grp_id) 
VALUES (3, 'physical', 703);

INSERT INTO grp (id,class__id,name,description,parent_id,secret)
VALUES (703, 23, 'Physical', 'General macro level science', 701, 1);

INSERT INTO member (id, grp__id, class__id, active) 
VALUES (703, 701, 20, 1);

INSERT INTO category_member (id, object_id, member__id)
VALUES (703, 3, 703);

-- -----------------------------------------------------------------------------
-- Biological

INSERT INTO category (id,directory,category_grp_id) 
VALUES (4, 'biological', 704);

INSERT INTO grp (id,class__id,name,description,parent_id,secret)
VALUES (704, 23, 'Biological', 'Bugs, bats and bees.', 701, 1);

INSERT INTO member (id, grp__id, class__id, active) 
VALUES (704, 701, 20, 1);

INSERT INTO category_member (id, object_id, member__id)
VALUES (704, 4, 704);


-- -----------------------------------------------------------------------------
-- Groups.
-- Hard Science.
INSERT INTO grp (id, parent_id, class__id, name, description, secret)
VALUES (51, NULL, 47, 'Hard Science', 'Hard Science Categories.', 0);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (51, 51, 20, 1);

INSERT INTO category_member (id, object_id, member__id)
VALUES (51, 1, 51); 

INSERT INTO member (id, grp__id, class__id, active)
VALUES (52, 51, 20, 1);

INSERT INTO category_member (id, object_id, member__id)
VALUES (52, 3, 52); 

-- Bio Science.
INSERT INTO grp (id, parent_id, class__id, name, description, secret)
VALUES (52, NULL, 47, 'Bio Science', 'Biological Science Categories.', 0);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (53, 52, 20, 1);

INSERT INTO category_member (id, object_id, member__id)
VALUES (53, 4, 53); 

