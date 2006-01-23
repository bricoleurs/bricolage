
-- Project:      Bricolage Business API
-- File:    Org.tst
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate$
-- Author: David Wheeler <david@justatheory.com>

INSERT INTO org (id, name, long_name, active)
VALUES (2, 'About.com', 'About.com, Inc.', 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (705, 3, 3, 1);

INSERT INTO org_member (id, object_id, member__id)
VALUES (12, 2, 705); 

INSERT INTO org (id, name, long_name, active)
VALUES (3, 'Red Hat', 'Red Hat, Inc.', 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (706, 3, 3, 1);

INSERT INTO org_member (id, object_id, member__id)
VALUES (13, 3, 706); 

INSERT INTO org (id, name, long_name, active)
VALUES (4, 'Red Herring', 'Red Herring, Inc.', 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (707, 3, 3, 1);

INSERT INTO org_member (id, object_id, member__id)
VALUES (14, 4, 707); 

INSERT INTO org (id, name, long_name, active)
VALUES (5, 'Cysco', 'Cysco Systems, Inc.', 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (708, 3, 3, 1);

INSERT INTO org_member (id, object_id, member__id)
VALUES (15, 5, 708); 

INSERT INTO org (id, name, long_name, active)
VALUES (6, 'Apple', 'Apple Computer, Inc.', 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (709, 3, 3, 1);

INSERT INTO org_member (id, object_id, member__id)
VALUES (16, 6, 709); 

INSERT INTO org (id, name, long_name, active)
VALUES (7, 'Primedia', 'Primedia, Inc.', 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (710, 3, 3, 1);

INSERT INTO org_member (id, object_id, member__id)
VALUES (17, 7, 710); 

INSERT INTO org (id, name, long_name, active)
VALUES (8, 'CNN', 'CNN Enterprises, Ltd.', 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (711, 3, 3, 1);

INSERT INTO org_member (id, object_id, member__id)
VALUES (18, 8, 711); 

INSERT INTO org (id, name, long_name, active)
VALUES (9, 'AP', 'Associated Press', 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (712, 3, 3, 1);

INSERT INTO org_member (id, object_id, member__id)
VALUES (19, 9, 712); 

INSERT INTO org (id, name, long_name, active)
VALUES (10, 'Reuters', 'Reuters Wire Service', 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (713, 3, 3, 1);

INSERT INTO org_member (id, object_id, member__id)
VALUES (20, 10, 713); 

INSERT INTO org (id, name, long_name, active)
VALUES (11, 'UPI', 'United Press International', 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (714, 3, 3, 1);

INSERT INTO org_member (id, object_id, member__id)
VALUES (21, 11, 714); 


