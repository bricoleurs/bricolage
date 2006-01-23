-- Project: Bricolage Business API
-- File:    Contact.tst
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate$
-- Author:  David Wheeler <david@justatheory.com>

--DELETE FROM map_contact_value;
--DELETE FROM map_person;
--DELETE FROM map where id < 1024;
--DELETE FROM contact_value;


-- David Email.
INSERT INTO contact_value (id, contact__id, value, active)
VALUES (1, 1, 'david@justatheory.com', 1);

INSERT INTO person__contact_value (person__id, contact_value__id)
VALUES (3, 1);

-- David Phone.
INSERT INTO contact_value (id, contact__id, value, active)
VALUES (2, 3, '(415) 262-7425', 1);

INSERT INTO person__contact_value (person__id, contact_value__id)
VALUES (3, 2);

-- David AIM.
INSERT INTO contact_value (id, contact__id, value, active)
VALUES (3, 9, 'dwTheory', 1);

INSERT INTO person__contact_value (person__id, contact_value__id)
VALUES (3, 3);

-- Garth Email.
INSERT INTO contact_value (id, contact__id, value, active)
VALUES (4, 1, 'garth@perijove.com', 1);

INSERT INTO person__contact_value (person__id, contact_value__id)
VALUES (2, 4);

-- Garth Work.
INSERT INTO contact_value (id, contact__id, value, active)
VALUES (5, 3, '(415) 645-9211', 1);

INSERT INTO person__contact_value (person__id, contact_value__id)
VALUES (2, 5);

-- Garth AIM.
INSERT INTO contact_value (id, contact__id, value, active)
VALUES (6, 9, 'mcnibblet', 1);

INSERT INTO person__contact_value (person__id, contact_value__id)
VALUES (2, 6);

-- Ek Email.
INSERT INTO contact_value (id, contact__id, value, active)
VALUES (7, 1, 'garth@perijove.com', 1);

INSERT INTO person__contact_value (person__id, contact_value__id)
VALUES (8, 7);

-- Mike Email.
INSERT INTO contact_value (id, contact__id, value, active)
VALUES (8, 1, 'miraso@pacbell.net', 1);

INSERT INTO person__contact_value (person__id, contact_value__id)
VALUES (4, 8);

-- Mike Home.
INSERT INTO contact_value (id, contact__id, value, active)
VALUES (9, 4, '(323) 465-1098', 1);

INSERT INTO person__contact_value (person__id, contact_value__id)
VALUES (4, 9);

-- Mike AIM.
INSERT INTO contact_value (id, contact__id, value, active)
VALUES (10, 9, 'chubbieleper', 1);

INSERT INTO person__contact_value (person__id, contact_value__id)
VALUES (4, 10);

-- Dave Email.
INSERT INTO contact_value (id, contact__id, value, active)
VALUES (11, 1, 'fretlessbass@home.com', 1);

INSERT INTO person__contact_value (person__id, contact_value__id)
VALUES (5, 11);

-- Dave Work.
INSERT INTO contact_value (id, contact__id, value, active)
VALUES (12, 3, '(415) 262-7426', 1);

INSERT INTO person__contact_value (person__id, contact_value__id)
VALUES (5, 12);

-- Dave AIM.
INSERT INTO contact_value (id, contact__id, value, active)
VALUES (13, 9, 'rankindaveyg', 1);

INSERT INTO person__contact_value (person__id, contact_value__id)
VALUES (5, 13);


