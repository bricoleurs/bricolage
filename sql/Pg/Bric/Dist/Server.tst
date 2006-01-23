-- Project: Bricolage Business API
-- File:    Server.tst
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate$
-- Author:  David Wheeler <david@justatheory.com>

DELETE FROM server;

INSERT INTO server (id, server_type__id, host_name, os, doc_root, login, password, cookie, active)
VALUES (1, 1, 'preview.foo.com', 'Unix', '/tmp/preview', 'upload', '', '', 1);

INSERT INTO server (id, server_type__id, host_name, os, doc_root, login, password, cookie, active)
VALUES (2, 2, 'ww1.foo.com', 'Unix', '/tmp/content', 'upload', 'daolpu', 'seoirnaiofnwe3890235r*Easf', 1);

INSERT INTO server (id, server_type__id, host_name, os, doc_root, login, password, cookie, active)
VALUES (3, 2, 'ww2.foo.com', 'Unix', '/tmp/content', 'upload', 'daolpu', 'seoiraw3984t98e3890235r*Easf', 1);

INSERT INTO server (id, server_type__id, host_name, os, doc_root, login, password, cookie, active)
VALUES (4, 2, 'ww3.foo.com', 'Unix', '/tmp/content', 'upload', 'daolpu', 'seoirnaiofnwe33QEDF;O ;RFWE*Easf', 1);

INSERT INTO server (id, server_type__id, host_name, os, doc_root, login, password, cookie, active)
VALUES (5, 2, 'ww4.foo.com', 'Unix', '/tmp/content', 'upload', 'daolpu', 'seoirQ89nfp0893j5vfe90sf', 1);


