-- Project: Bricolage Business API
-- File:    User.tst
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate$
-- Author:  David Wheeler <david@justatheory.com>

-- The password for all these users is "BricolageRules!".

--DELETE FROM usr where id > 0;
--DELETE FROM user_member where id > 0;
--DELETE FROM member WHERE id between 15 and 32;
--DELETE FROM member WHERE id between 101 and 110;
--DELETE FROM grp WHERE id IN (203,204,205,206);

INSERT INTO usr (id, login, password, active)
VALUES (1, 'kristee', '706c4007f7fb980574553e3bfb233fc5', 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (15, 2, 2, 1);

INSERT INTO user_member (id, object_id, member__id)
VALUES (15, 1, 15); 

INSERT INTO usr (id, login, password, active)
VALUES (2, 'mcnibblet', '215b5a946bdbe07c5cc9c0045308aa8a', 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (16, 2, 2, 1);

INSERT INTO user_member (id, object_id, member__id)
VALUES (2, 2, 16); 

INSERT INTO usr (id, login, password, active)
VALUES (3, 'theory', '7af05dc75c0c63d76848f2b7afd5d314', 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (17, 2, 2, 1);

INSERT INTO user_member (id, object_id, member__id)
VALUES (3, 3, 17); 

INSERT INTO usr (id, login, password, active)
VALUES (4, 'chubbieleper', 'b159c567ef5aece28d161571f7a62697', 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (18, 2, 2, 1);

INSERT INTO user_member (id, object_id, member__id)
VALUES (4, 4, 18); 

INSERT INTO usr (id, login, password, active)
VALUES (5, 'rankindaveyg', '830c8c5ad25e4ed0bc7ebfdb0c0cf530', 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (19, 2, 2, 1);

INSERT INTO user_member (id, object_id, member__id)
VALUES (5, 5, 19); 

INSERT INTO usr (id, login, password, active)
VALUES (6, 'splath', '1322918ae096d7a99d6c9dfb453899e8', 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (103, 2, 2, 1);

INSERT INTO user_member (id, object_id, member__id)
VALUES (103, 6, 103); 

-- Test user with password 'testme'.
INSERT INTO usr (id, login, password, active)
VALUES (7, 'tester', '572ebe149f22d49683e9364b5ffd0130', 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (104, 2, 2, 1);

INSERT INTO user_member (id, object_id, member__id)
VALUES (104, 7, 104); 

-- Another Test user with password 'testme'.
INSERT INTO usr (id, login, password, active)
VALUES (8, 'tester2', '572ebe149f22d49683e9364b5ffd0130', 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (105, 2, 2, 1);

INSERT INTO user_member (id, object_id, member__id)
VALUES (105, 8, 104); 

-- Yet Another Test user with password 'testme'.
INSERT INTO usr (id, login, password, active)
VALUES (9, 'tester3', '572ebe149f22d49683e9364b5ffd0130', 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (106, 2, 2, 1);

INSERT INTO user_member (id, object_id, member__id)
VALUES (106, 9, 104); 


-- Test user 'zooey' with easy to type pass 'testme'
INSERT INTO usr (id, login, password, active)
VALUES (11, 'zooey', '572ebe149f22d49683e9364b5ffd0130', 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (32, 2, 2, 1);

INSERT INTO user_member (id, object_id, member__id)
VALUES (32, 11, 32); 

-- Groups Memberships.
-- Administrators.
INSERT INTO member (id, grp__id, class__id, active)
VALUES (20, 6, 2, 1);

INSERT INTO user_member (id, object_id, member__id)
VALUES (6, 1, 20); 

INSERT INTO member (id, grp__id, class__id, active)
VALUES (21, 6, 2, 1);

INSERT INTO user_member (id, object_id, member__id)
VALUES (7, 2, 21); 

INSERT INTO member (id, grp__id, class__id, active)
VALUES (24, 6, 2, 1);

INSERT INTO user_member (id, object_id, member__id)
VALUES (10, 3, 24); 

INSERT INTO member (id, grp__id, class__id, active)
VALUES (25, 6, 2, 1);

INSERT INTO user_member (id, object_id, member__id)
VALUES (11, 4, 25); 

INSERT INTO member (id, grp__id, class__id, active)
VALUES (26, 6, 2, 1);

INSERT INTO user_member (id, object_id, member__id)
VALUES (12, 5, 26); 

INSERT INTO member (id, grp__id, class__id, active)
VALUES (107, 6, 2, 1);

INSERT INTO user_member (id, object_id, member__id)
VALUES (107, 6, 107); 

INSERT INTO member (id, grp__id, class__id, active)
VALUES (108, 6, 2, 1);

INSERT INTO user_member (id, object_id, member__id)
VALUES (108, 7, 108); 

INSERT INTO member (id, grp__id, class__id, active)
VALUES (109, 6, 2, 1);

INSERT INTO user_member (id, object_id, member__id)
VALUES (109, 8, 109); 

INSERT INTO member (id, grp__id, class__id, active)
VALUES (110, 6, 2, 1);

INSERT INTO user_member (id, object_id, member__id)
VALUES (110, 9, 110); 


-- Editors.
INSERT INTO member (id, grp__id, class__id, active)
VALUES (22, 7, 2, 1);

INSERT INTO user_member (id, object_id, member__id)
VALUES (8, 1, 22); 

INSERT INTO member (id, grp__id, class__id, active)
VALUES (23, 7, 2, 1);

INSERT INTO user_member (id, object_id, member__id)
VALUES (9, 4, 23); 

