-- Project: Bricolage Business API
-- File:    Job.tst
-- VERSION: $Revision: 1.1 $
--
-- $Date: 2003/02/02 19:46:47 $
-- Author:  David Wheeler <david@wheeler.net>

DELETE FROM job;

INSERT INTO job (id, name, usr__id, sched_time, comp_time, expire, tries, pending)
VALUES (1, 'Job One', 1, '2001-02-28 14:54:34', '2001-02-28 14:55:17', 0, 1, 0);

INSERT INTO job__server_type (job__id, server_type__id)
VALUES (1, 2);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (724, 30, 54, 1);

INSERT INTO job_member (id, object_id, member__id)
VALUES (1, 1, 724); 

--INSERT INTO job__resource (job__id, resource__id)
--VALUES (1, 1);

--INSERT INTO job__resource (job__id, resource__id)
--VALUES (1, 2);


INSERT INTO job (id, name, usr__id, sched_time, comp_time, expire, tries, pending)
VALUES (2, 'Job 2', 2, '2001-02-28 14:54:34', NULL, 0, 0, 0);

INSERT INTO job__server_type (job__id, server_type__id)
VALUES (2, 1);

INSERT INTO job__server_type (job__id, server_type__id)
VALUES (2, 2);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (725, 30, 54, 1);

INSERT INTO job_member (id, object_id, member__id)
VALUES (2, 2, 725); 

--INSERT INTO job__resource (job__id, resource__id)
--VALUES (2, 2);



