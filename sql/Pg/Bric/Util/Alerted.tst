-- Project: Bricolage Business API
-- File:    Alerted.tst
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate$
-- Author:  David Wheeler <david@justatheory.com>


DELETE FROM alerted;
DELETE FROM alerted__contact_value;

INSERT INTO alerted (id, usr__id, alert__id)
VALUES (1, 2, 1);

INSERT INTO alerted (id, usr__id, alert__id)
VALUES (2, 3, 1);

INSERT INTO alerted (id, usr__id, alert__id)
VALUES (3, 4, 1);

INSERT INTO alerted__contact_value
       (alerted__id, contact__id, contact_value__value, sent_time)
VALUES (1, 4, 'garth@perijove.com', CURRENT_TIMESTAMP);

INSERT INTO alerted__contact_value
       (alerted__id, contact__id, contact_value__value, sent_time)
VALUES (2, 1, 'david@justatheory.com', CURRENT_TIMESTAMP);

INSERT INTO alerted__contact_value
       (alerted__id, contact__id, contact_value__value, sent_time)
VALUES (3, 3, 'dwTheory', CURRENT_TIMESTAMP);

INSERT INTO alerted__contact_value
       (alerted__id, contact__id, contact_value__value, sent_time)
VALUES (3, 8, 'miraso@pacbell.net', CURRENT_TIMESTAMP);
