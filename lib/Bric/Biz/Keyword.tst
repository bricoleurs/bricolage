-- -----------------------------------------------------------------------------
-- Keyword.tst
--
-- VERSION: $Revision: 1.1 $
--
-- This SQL creates test keyword values.
--

DELETE FROM keyword where id > 0;

INSERT INTO keyword (id,name,screen_name,sort_name,meaning,prefered,active)
VALUES (1, 'george w.', 'George Washington', 'Washington, George', 'First American president', 1, 1);

INSERT INTO keyword (id,name,screen_name,sort_name,meaning,prefered,active)
VALUES (2, 'mcnibblet', 'Garth Webb', 'Webb, Garth', 'Developer A', 1, 1);

INSERT INTO keyword (id,name,screen_name,sort_name,meaning,prefered,active)
VALUES (3, 'mathewdpklanier', 'Matt Lanier', 'Lanier, Matt', 'Manager A', 1, 1);

INSERT INTO keyword (id,name,screen_name,sort_name,meaning,prefered,active)
VALUES (4, 'goatPg', 'Mike Soderstrom', 'Soderstrom, Mike', 'Developer B', 1, 1);

INSERT INTO keyword (id,name,screen_name,sort_name,meaning,prefered,active)
VALUES (5, 'dwtheory', 'David Wheeler', 'Wheeler, David', 'Developer C', 1, 1);

INSERT INTO keyword (id,name,screen_name,sort_name,meaning,prefered,active)
VALUES (6, 'rankinDaveyG', 'Dave Rankin', 'Rankin, Dave', 'Developer D', 1, 1);
