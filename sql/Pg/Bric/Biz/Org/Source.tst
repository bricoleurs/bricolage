
-- Project:      Bricolage Business API
-- File:    Source.tst
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate$
-- Author: David Wheeler <david@justatheory.com>


INSERT INTO source (id, org__id, name, description, expire, active)
VALUES (2, 9, 'AP 30', 'Associated Press 30 Day', 30, 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (430, 5, 35, 1);

INSERT INTO source_member (id, object_id, member__id)
VALUES (12, 2, 430); 

INSERT INTO source (id, org__id, name, description, expire, active)
VALUES (3, 9, 'AP 45', 'Associated Press 45 Day', 45, 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (431, 5, 35, 1);

INSERT INTO source_member (id, object_id, member__id)
VALUES (13, 3, 431); 

INSERT INTO source (id, org__id, name, description, expire, active)
VALUES (4, 9, 'AP Permanent', 'Associated Press Permanent', 0, 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (432, 5, 35, 1);

INSERT INTO source_member (id, object_id, member__id)
VALUES (14, 4, 432); 

INSERT INTO source (id, org__id, name, description, expire, active)
VALUES (5, 10, 'Reuters 10', 'Reuters 10 Day', 10, 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (433, 5, 35, 1);

INSERT INTO source_member (id, object_id, member__id)
VALUES (15, 5, 433); 

INSERT INTO source (id, org__id, name, description, expire, active)
VALUES (6, 10, 'Reuters 30', 'Reuters 30 Day', 30, 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (434, 5, 35, 1);

INSERT INTO source_member (id, object_id, member__id)
VALUES (16, 6, 434); 

INSERT INTO source (id, org__id, name, description, expire, active)
VALUES (7, 11, 'UPI', 'United Press International', 0, 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (435, 5, 35, 1);

INSERT INTO source_member (id, object_id, member__id)
VALUES (17, 7, 435); 




