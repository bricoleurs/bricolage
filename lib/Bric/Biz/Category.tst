-- -----------------------------------------------------------------------------
-- Catergory.val
--
-- VERSION: $Revision: 1.4.2.1 $
--
-- Test values.
--

DELETE FROM category        WHERE id IN (1, 2, 3, 4);
DELETE FROM grp             WHERE id IN (701, 702, 703, 704);
DELETE FROM member          WHERE id IN (702, 703, 704);
DELETE FROM category_member WHERE id IN (702, 703, 704);

-- -----------------------------------------------------------------------------
-- Science

INSERT INTO category (id,directory,uri,parent_id, name, description, asset_grp_id) 
VALUES (1, 'science', '/science/', 0, 'Science', 'All things sciencey', 53);

-- -----------------------------------------------------------------------------
-- Material

INSERT INTO category (id,directory,uri,parent_id, name, description, asset_grp_id) 
VALUES (2, 'material', '/science/material', 1, 'Material',
        'The study of new materials', 54);

-- -----------------------------------------------------------------------------
-- Physical

INSERT INTO category (id,directory,uri,parent_id, name, description, asset_grp_id) 
VALUES (3, 'physical', '/science/physical', 1, 'Physical',
        'General macro level science', 55);

-- -----------------------------------------------------------------------------
-- Biological

INSERT INTO category (id, directory, uri,parent_id, name, description, asset_grp_id)
VALUES (4, 'biological', '/science/biological', 1, 'Biological',
        'Bugs, bats and bees.', 56);

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

-- Asset groups.
INSERT INTO grp (id, parent_id, class__id, name, description, secret, permanent)
VALUES (53, NULL, 43, 'Category Assets', 'Science', 1, 0);

INSERT INTO grp (id, parent_id, class__id, name, description, secret, permanent)
VALUES (54, NULL, 43, 'Category Assets', 'Material', 1, 0);

INSERT INTO grp (id, parent_id, class__id, name, description, secret, permanent)
VALUES (55, NULL, 43, 'Category Assets', 'Physical', 1, 0);

INSERT INTO grp (id, parent_id, class__id, name, description, secret, permanent)
VALUES (56, NULL, 43, 'Category Assets', 'Biological', 1, 0);

-- All Categories.
INSERT INTO member (id, grp__id, class__id, active)
VALUES (54, 26, 20, 1);

INSERT INTO category_member (id, object_id, member__id)
VALUES (57, 1, 54); 

INSERT INTO member (id, grp__id, class__id, active)
VALUES (55, 26, 20, 1);

INSERT INTO category_member (id, object_id, member__id)
VALUES (58, 2, 55); 

INSERT INTO member (id, grp__id, class__id, active)
VALUES (56, 26, 20, 1);

INSERT INTO category_member (id, object_id, member__id)
VALUES (59, 3, 56); 

INSERT INTO member (id, grp__id, class__id, active)
VALUES (57, 26, 20, 1);

INSERT INTO category_member (id, object_id, member__id)
VALUES (60, 4, 57); 
