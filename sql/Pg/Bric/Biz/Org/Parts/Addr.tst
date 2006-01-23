-- Project:      Bricolage Business API
-- File:    Address.tst
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate$
-- Author: David Wheeler <david@justatheory.com>

-- Delete existing records.

DELETE FROM addr_part;
DELETE FROM addr;


-- Main Address Records.

INSERT INTO addr(id, org__id, type, active)
VALUES (1, 1, 'Main', 1);

INSERT INTO addr(id, org__id, type, active)
VALUES (2, 1, 'New York City', 1);

INSERT INTO addr(id, org__id, type, active)
VALUES (3, 1, 'Washington, DC', 1);

INSERT INTO addr(id, org__id, type, active)
VALUES (4, 3, 'San Francisco', 1);

INSERT INTO addr(id, org__id, type, active)
VALUES (5, 3, 'Chapel Hill', 1);

INSERT INTO addr(id, org__id, type, active)
VALUES (6, 4, 'SoMa', 1);

INSERT INTO addr(id, org__id, type, active)
VALUES (7, 4, 'Tenderloin', 1);


-- Address Parts.
-- Lines
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (1, 1, 1, '22 Fourth Street');
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (2, 1, 1, '16th Floor');

-- City
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (3, 1, 2, 'San Francisco');

-- State
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (4, 1, 3, 'CA');

-- Code
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (5, 1, 4, '94103');

-- Country
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (6, 1, 5, 'USA');

-- Lines
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (7, 2, 1, '345 Madison Avenue');
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (8, 2, 1, 'Suite 594');

-- City
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (9, 2, 2, 'New York');

-- State
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (10, 2, 3, 'NY');

-- Code
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (11, 2, 4, '10025');

-- Country
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (12, 2, 5, 'USA');


-- Lines
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (13, 3, 1, '943 Pennsylvania Ave.');
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (14, 3, 1, '29th Floor');
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (15, 3, 1, 'Suite 6B');

-- City
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (16, 3, 2, 'Washington, DC');

-- Code
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (17, 3, 3, '21569');

-- Country
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (18, 3, 5, 'USA');


-- Lines
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (19, 4, 1, '34 Mission Ave.');
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (20, 4, 1, 'Room 007');

-- City
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (21, 4, 2, 'San Francisco');

-- State
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (22, 4, 3, 'CA');

-- Code
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (23, 4, 4, '94112');

-- Country
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (24, 4, 5, 'USA');


-- Lines
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (25, 5, 1, '225 Red Hat Ln.');

-- City
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (26, 5, 2, 'Chapel Hill');

-- State
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (27, 5, 3, 'NC');

-- Code
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (28, 5, 4, '26987');

-- Country
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (29, 5, 5, 'USA');


-- Lines
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (30, 6, 1, '3456 22nd Street');

-- City
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (31, 6, 2, 'San Francisco');

-- State
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (32, 6, 3, 'CA');

-- Code
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (33, 6, 4, '94115');

-- Country
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (34, 6, 5, 'USA');


-- Lines
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (35, 7, 1, '293 Geary Ave.');

-- City
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (36, 7, 2, 'San Francisco');

-- State
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (37, 7, 3, 'CA');

-- Code
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (38, 7, 4, '94111');

-- Country
INSERT INTO addr_part (id, addr__id, addr_part_type__id, value)
VALUES (39, 7, 5, 'USA');


-- Mappings to Org::Person objects.
INSERT INTO person_org__addr(person_org__id, addr__id)
VALUES (1, 1);

INSERT INTO person_org__addr(person_org__id, addr__id)
VALUES (1, 2);

INSERT INTO person_org__addr(person_org__id, addr__id)
VALUES (3, 2);

INSERT INTO person_org__addr(person_org__id, addr__id)
VALUES (4, 6);

