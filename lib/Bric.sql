-- Project: Bricolage
-- VERSION: $Revision: 1.5 $
--
-- $Date: 2001-12-04 18:17:43 $
-- Target DBMS: PostgreSQL 7.1.2
-- Author: David Wheeler <david@wheeler.net>
--

-- This DDL is for the creation of universal stuff needed by other DDLs, such as
-- functions.

--
-- Functions. 
--
-- This function allows us to have case-insensitive indexes on varchar fields.
-- It shouldn't be needed anymore once 7.1 ships.
-- CREATE   FUNCTION lower(varchar)
-- RETURNS  TEXT AS 'lower' LANGUAGE 'internal'
-- WITH     (iscachable);



