-- Project: Bricolage
-- VERSION: $Revision: 1.5 $
--
-- $Date: 2004-02-14 02:10:08 $
-- Author: David Wheeler <david@wheeler.net>
--

-- This DDL is for the creation of universal stuff needed by other DDLs, such as
-- functions.

--
-- Functions. 
--

-- This funtion allows us to create UNIQUE indices that combine a lowercased
-- TEXT (or VARCHAR) column with a NUMERIC column. See Bric/Util/AlertType.sql
-- for an example.
CREATE   FUNCTION lower_text_num(TEXT, NUMERIC(10, 0))
RETURNS  TEXT AS 'SELECT LOWER($1) || to_char($2, ''|FM9999999999'')'
LANGUAGE 'sql'
WITH     (ISCACHABLE);

-- This function is used to append a space followed by a number to a TEXT
-- string. It is used primarily for the id_list aggregate (below).
CREATE   FUNCTION append_id(TEXT, NUMERIC(10,0))
RETURNS  TEXT AS 'SELECT $1 || '' '' || CAST($2 AS TEXT)'
LANGUAGE 'sql'
WITH     (ISCACHABLE, ISSTRICT);

-- This aggregate is designed to concatenate all of the IDs that would
-- otherwise cause a query to return multiple rows into a single value
-- with each ID separated by a space. This makes it easy for us to pull
-- out the list of IDs using split, _and_ keeps the entire contents of
-- an object in a single row, thus also enabling the use of OFFSET and
-- LIMIT.
CREATE AGGREGATE id_list (
    SFUNC    = append_id,
    BASETYPE = NUMERIC(10, 0),
    STYPE    = TEXT,
    INITCOND = ''
);