-- Project: Bricolage Business API
-- File:    Resource.tst
-- VERSION: $Revision: 1.1 $
--
-- $Date: 2001-09-06 21:54:31 $
-- Author:  David Wheeler <david@wheeler.net>

/*

DELETE FROM story__resource;
DELETE FROM media__resource;
DELETE FROM resource;

INSERT INTO resource (id, parent_id, media_type__id, path, uri, size, mod_time, is_dir)
VALUES (1, NULL, 0, '/data/content/tech/feature', '/tech/feature', 0, '2001-02-14 10:45:34', 1);

INSERT INTO resource (id, parent_id, media_type__id, path, uri, size, mod_time, is_dir)
VALUES (2, 1, 77, '/data/content/tech/feature/index.html', '/tech/feature/index.html', 324, '2001-02-14 10:45:34', 0);

INSERT INTO story__resource (story__id, resource__id)
VALUES (1, 1);

INSERT INTO story__resource (story__id, resource__id)
VALUES (2, 1);

INSERT INTO story__resource (story__id, resource__id)
VALUES (3, 1);

INSERT INTO media__resource (media__id, resource__id)
VALUES (2, 1);

INSERT INTO media__resource (media__id, resource__id)
VALUES (16, 1);

INSERT INTO media__resource (media__id, resource__id)
VALUES (32, 1);

*/


/*
Change Log:
$Log: Resource.tst,v $
Revision 1.1  2001-09-06 21:54:31  wheeler
Initial revision

*/
