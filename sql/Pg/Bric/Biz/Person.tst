-- Project: Bricolage Business API
-- File:    Person.tst
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate$
-- Author:  David Wheeler <david@justatheory.com>

--DELETE FROM person where id > 0;
--DELETE FROM attr_person WHERE ID < 1024;
--DELETE FROM attr_person_val WHERE ID < 1024;
--DELETE FROM attr_person_meta WHERE ID < 1024;
--DELETE FROM grp WHERE id IN (201, 202);
--DELETE FROM person_member where id > 0;
--DELETE FROM member WHERE id between 2 and 14;

INSERT INTO person (id, lname, fname, mname, prefix, suffix, active)
VALUES (1, 'Rosendahl', 'Kristee', '', 'Ms.', '', 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (101, 1, 1, 1);

INSERT INTO person_member (id, object_id, member__id)
VALUES (101, 1, 101);

-- Add her to the 'Illustrators' group.
INSERT INTO member (id, grp__id, class__id, active)
VALUES (11, 40, 1, 1);

INSERT INTO person_member (id, object_id, member__id)
VALUES (11, 1, 11); 

INSERT INTO person (id, lname, fname, mname, prefix, suffix, active)
VALUES (2, 'Webb', 'Garth', '', 'Mr.', '' , 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (102, 1, 1, 1);

INSERT INTO person_member (id, object_id, member__id)
VALUES (2, 2, 102); 

INSERT INTO person (id, lname, fname, mname, prefix, suffix, active)
VALUES (3, 'Wheeler', 'David', 'Erin', 'Mr.', 'MA', 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (3, 1, 1, 1);

INSERT INTO person_member (id, object_id, member__id)
VALUES (3, 3, 3); 

-- Add him to the 'Writers' group.
INSERT INTO member (id, grp__id, class__id, active)
VALUES (12, 39, 1, 1);

INSERT INTO person_member (id, object_id, member__id)
VALUES (12, 3, 12); 

INSERT INTO person (id, lname, fname, mname, prefix, suffix, active)
VALUES (4, 'Soderstrom', 'Mike', '', 'Mr.', '', 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (4, 1, 1, 1);

INSERT INTO person_member (id, object_id, member__id)
VALUES (4, 4, 4); 

INSERT INTO person (id, lname, fname, mname, prefix, suffix, active)
VALUES (5, 'Gantenbein', 'Dave', '', 'Mr.', '', 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (5, 1, 1, 1);

INSERT INTO person_member (id, object_id, member__id)
VALUES (5, 5, 5); 

-- Add him to the 'Illustrators' group.
INSERT INTO member (id, grp__id, class__id, active)
VALUES (13, 40, 1, 1);

INSERT INTO person_member (id, object_id, member__id)
VALUES (13, 5, 13); 

INSERT INTO person (id, lname, fname, mname, prefix, suffix, active)
VALUES (6, 'Plath', 'Sara', '', '', '', 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (6, 1, 1, 1);

INSERT INTO person_member (id, object_id, member__id)
VALUES (6, 6, 6); 

-- Add her to the 'Writers' group.
INSERT INTO member (id, grp__id, class__id, active)
VALUES (14, 39, 1, 1);

INSERT INTO person_member (id, object_id, member__id)
VALUES (14, 6, 14); 

INSERT INTO person (id, lname, fname, mname, prefix, suffix, active)
VALUES (7, 'Tester', 'Iama', '', 'Ms.', '', 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (7, 1, 1, 1);

INSERT INTO person_member (id, object_id, member__id)
VALUES (7, 7, 7); 

INSERT INTO person (id, lname, fname, mname, prefix, suffix, active)
VALUES (8, 'Tester', 'Another', '', 'Ms.', '', 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (8, 1, 1, 1);

INSERT INTO person_member (id, object_id, member__id)
VALUES (8, 8, 8); 

INSERT INTO person (id, lname, fname, mname, prefix, suffix, active)
VALUES (9, 'Tester', 'Yet', 'Another', 'Ms.', '', 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (9, 1, 1, 1);

INSERT INTO person_member (id, object_id, member__id)
VALUES (9, 9, 9); 

INSERT INTO person (id, lname, fname, mname, prefix, suffix, active)
VALUES (10, 'Fajen', 'Joe', '', 'Mr.', '', 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (10, 1, 1, 1);

INSERT INTO person_member (id, object_id, member__id)
VALUES (10, 10, 10); 

-- Test user zooey
INSERT INTO person (id, lname, fname, mname, prefix, suffix, active)
VALUES (11, 'Webb', 'Zooey', 'Tiberious', 'Mr.', 'II', 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (31, 1, 1, 1);

INSERT INTO person_member (id, object_id, member__id)
VALUES (31, 11, 31); 


/*

-- Attributes
-- Birthday
INSERT INTO attr_person (id, subsys, name, sql_type, active)
VALUES (1, '_DEFAULT', 'Birthday', 'date', 1);

INSERT INTO attr_person_meta(id, attr__id, name, value, active)
VALUES (1, 1, 'required', '1', 1);

INSERT INTO attr_person_meta(id, attr__id, name, value, active)
VALUES (2, 1, 'description', 'Don''t you know what a birthday is???', 1);

INSERT INTO attr_person_val (id, object__id, attr__id, date_val, serial, active)
VALUES (1, 1, 1, '2000-10-01 00:00:00', 0, 1);

INSERT INTO attr_person_val (id, object__id, attr__id, date_val, serial, active)
VALUES (2, 3, 1, '1968-12-19 00:00:00', 0, 1);

INSERT INTO attr_person_val (id, object__id, attr__id, date_val, serial, active)
VALUES (3, 8, 1, '1968-12-30 00:00:00', 0, 1);

INSERT INTO attr_person_val (id, object__id, attr__id, date_val, serial, active)
VALUES (4, 2, 1, '1961-05-08 00:00:00', 0, 1);

-- Bio
INSERT INTO attr_person (id, subsys, name, sql_type, active)
VALUES (2, '_DEFAULT', 'Bio', 'blob', 1);

INSERT INTO attr_person_blob_val (id, object__id, attr__id, value, serial, active)
VALUES (5, 1, 2, 'Ayeta Alla Yoo, a.k.a. "Castellan," was born in the back of Ian Kallen''s mind in the fall of 2000. He has been terrorizing the Bricolage developers ever since.', 0, 1);

INSERT INTO attr_person_blob_val (id, object__id, attr__id, value, serial, active)
VALUES (6, 3, 2, 'David Wheeler lives in San Francisco with his wife, Julie, and his two cats, Sweetpea and Biscuit.', 0, 1);

INSERT INTO attr_person_blob_val (id, object__id, attr__id, value, serial, active)
VALUES (7, 2, 2, 'Ian Kallen was born in San Francisco, somehow managed to get through the 80s without becoming a fan of New Wave music, and now lives in the Presidio with his wife and two children.', 0, 1);

INSERT INTO attr_person_blob_val (id, object__id, attr__id, value, serial, active)
VALUES (8, 4, 2, 'Sara Wood was born in the bayous of Louisianna, despite the fact that everyone can tell that she has more European sensibilities than that, and that her accent is Australian-influenced.', 0, 1);


-- Nickname
INSERT INTO attr_person (id, subsys, name, sql_type, active)
VALUES (3, '_DEFAULT', 'Nickname', 'short', 1);

INSERT INTO attr_person_meta(id, attr__id, name, value, active)
VALUES (3, 3, 'required', 0, 1);

INSERT INTO attr_person_meta(id, attr__id, name, value, active)
VALUES (4, 3, 'description', 'Another name by which the person is known.', 1);

INSERT INTO attr_person_val (id, object__id, attr__id, short_val, serial, active)
VALUES (9, 1, 3, 'Castellan', 0, 1);

INSERT INTO attr_person_val (id, object__id, attr__id, short_val, serial, active)
VALUES (10, 2, 3, 'Spidaman', 0, 1);

INSERT INTO attr_person_val (id, object__id, attr__id, short_val, serial, active)
VALUES (11, 3, 3, 'Theory', 0, 1);

INSERT INTO attr_person_val (id, object__id, attr__id, short_val, serial, active)
VALUES (12, 8, 3, 'Eek', 0, 1);


-- Pseudonym
INSERT INTO attr_person (id, subsys, name, sql_type, active)
VALUES (4, '_DEFAULT', 'Pseudonym', 'short', 1);

INSERT INTO attr_person_meta(id, attr__id, name, value, active)
VALUES (5, 4, 'required', 0, 1);

INSERT INTO attr_person_meta(id, attr__id, name, value, active)
VALUES (6, 4, 'description', 'Put in a pseudonym if the person wishes to be published with that name only.', 1);

INSERT INTO attr_person_val (id, object__id, attr__id, short_val, serial, active)
VALUES (13, 1, 4, 'Dom Castellan', 0, 1);

INSERT INTO attr_person_val (id, object__id, attr__id, short_val, serial, active)
VALUES (14, 3, 4, 'Arthur Dent', 0, 1);

INSERT INTO attr_person_val (id, object__id, attr__id, short_val, serial, active)
VALUES (15, 2, 4, 'Marge N. O''Vera', 0, 1);

*/


