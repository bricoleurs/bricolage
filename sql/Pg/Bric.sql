-- Project: Bricolage
-- VERSION: $Revision: 1.1.4.1 $
--
-- $Date: 2003-03-15 03:59:50 $
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
-- RETURNS  TEXT AS 'lower'
-- LANGUAGE 'internal'
-- WITH     (iscachable);


-- This funtion allows us to create UNIQUE indices that combine a lowercased
-- TEXT (or VARCHAR) column with a NUMERIC column. See Bric/Util/AlertType.sql
-- for an example.
CREATE   FUNCTION lower_text_num(TEXT, NUMERIC(10, 0))
RETURNS  TEXT AS 'SELECT LOWER($1) || to_char($2, ''|FM9999999999'')'
LANGUAGE 'sql'
WITH     (immutable);
