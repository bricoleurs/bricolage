-- Project: Bricolage Business API
-- File:    Person.tst
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate$
-- Author:  David Wheeler <david@justatheory.com>

-- Delete existing records.

DELETE FROM person_org;

INSERT INTO person_org (id, person__id, org__id, role, department, title, active)
VALUES (1, 1, 1, 'Employee', 'Engineering', 'Castellan', 1);

INSERT INTO person_org (id, person__id, org__id, role, department, title, active)
VALUES (2, 3, 4, 'Member', null, null, 1);

INSERT INTO person_org (id, person__id, org__id, role, department, title, active)
VALUES (3, 2, 5, 'Employee', 'Human Resources', 'Personnell Manager', 1);

INSERT INTO person_org (id, person__id, org__id, role, department, title, active)
VALUES (4, 3, 1, 'Employee', 'Tech Department', 'Senior Software Engineer', 1);

