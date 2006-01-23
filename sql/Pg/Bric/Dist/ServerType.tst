-- Project: Bricolage Business API
-- File:    ServerType.tst
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate$
-- Author:  David Wheeler <david@justatheory.com>

DELETE FROM server_type;

INSERT INTO server_type (id, class__id, name, description, site__id, copyable, publish, preview, active)
VALUES (1, 12, 'Preview Server', 'Servers of this type handle previews.', 100, 0, 0, 1, 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (726, 29, 52, 1);

INSERT INTO dest_member (id, object_id, member__id)
VALUES (1, 1, 726); 

INSERT INTO server_type (id, class__id, name, description, site__id, copyable, publish, preview, active)
VALUES (2, 11, 'Production', 'These are production servers.', 100, 0, 1, 0, 1);

INSERT INTO member (id, grp__id, class__id, active)
VALUES (727, 29, 52, 1);

INSERT INTO dest_member (id, object_id, member__id)
VALUES (2, 2, 727); 

INSERT INTO server_type__output_channel (server_type__id, output_channel__id)
VALUES (1, 1);

INSERT INTO server_type__output_channel (server_type__id, output_channel__id)
VALUES (1, 2);

INSERT INTO server_type__output_channel (server_type__id, output_channel__id)
VALUES (2, 1);

INSERT INTO server_type__output_channel (server_type__id, output_channel__id)
VALUES (2, 2);

INSERT INTO server_type__output_channel (server_type__id, output_channel__id)
VALUES (2, 3);



