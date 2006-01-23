-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate$
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@justatheory.com>
--

DELETE FROM alert_type;
DELETE FROM alert_type__grp__contact;
DELETE FROM alert_type__usr__contact;

INSERT INTO alert_type (id, event_type__id, usr__id, name, subject, message)
VALUES (1, 1026, 3, 'Story Published', '$trig_full_name Published Story',
        'Story "$title" was published by $trig_full_name');

INSERT INTO alert_type__usr__contact (alert_type__id, usr__id, contact__id)
VALUES (1, 3, 1);

INSERT INTO alert_type (id, event_type__id, usr__id, name, subject, message)
VALUES (2, 1070, 1, 'Another Password Changed', '$name Password Changed',
        '$name''s password was changed by $trig_name');

INSERT INTO alert_type (id, event_type__id, usr__id, name, subject, message)
VALUES (3, 1070, 4, 'Yet Another Password Changed', '$name Password Changed',
        '$name''s password was changed by $trig_name');

INSERT INTO alert_type (id, event_type__id, usr__id, name, subject, message)
VALUES (4, 1070, 2, 'Final Password Changed', '$name Password Changed',
        '$name''s password was changed by $trig_name');





