-- Project: Bricolage
-- VERSION: $Revision: 1.3 $
--
-- $Date: 2001-10-11 00:34:54 $
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@wheeler.net>
--


DELETE FROM alert;

INSERT INTO alert (id, event__id, alert_type__id, subject, message, timestamp)
VALUES (1, 1, 1,
        'Garth Webb Published Story', 'Story "Bushwhacked!" was published by Garth Webb',
        CURRENT_TIMESTAMP);

INSERT INTO alert (id, event__id, alert_type__id, subject, message, timestamp)
VALUES (2, 2, 1,
        'Garth Webb Password Changed', 'Garth Webb''s password was changed by David Wheeler',
        CURRENT_TIMESTAMP);

INSERT INTO alert (id, event__id, alert_type__id, subject, message, timestamp)
VALUES (3, 3, 2,
        'David Wheeler Password Changed', 'David Wheeler''s password was changed by Dave Gantenbein',
        CURRENT_TIMESTAMP);



