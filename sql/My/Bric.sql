-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate: 2006-03-18 03:10:10 +0200 (Sat, 18 Mar 2006) $
-- Author: David Wheeler <david@justatheory.com>
--

-- This DDL is for the creation of universal stuff needed by other DDLs, such as
-- functions.

--
-- Functions. 
--

-- This function allows us to create UNIQUE indices that combine a lowercased
-- TEXT (or VARCHAR) column with an INTEGER column. See Bric/Util/AlertType.sql
-- for an example.
CREATE   FUNCTION lower_text_num(p1 TEXT, p2 INTEGER) RETURNS TEXT
begin 
    RETURN SELECT LOWER(p1) || to_char(p2, ''|FM9999999999'')
end
LANGUAGE SQL
DETERMINISTIC;

/* XXX Once we require 7.4 or later (2.0?), dump the function and aggregate
 * below in favor of this aggregate:

CREATE AGGREGATE array_accum (
    sfunc    = array_append,
    basetype = anyelement,
    stype    = anyarray,
    initcond = '{}'
);

 * Then change the usage from id_list(foo) to
 * array_to_string(array_accum(foo), ' ')

*/

-- This function is used to append a space followed by a number to a TEXT
-- string. It is used primarily for the id_list aggregate (below). We omit
-- the ID 0 because it is a hidden, secret group to which permissions do not
-- apply.
CREATE   FUNCTION append_id(TEXT, INTEGER)
RETURNS  TEXT AS '
    SELECT CASE WHEN $2 = 0 THEN
                $1
           ELSE
                $1 || '' '' || CAST($2 AS TEXT)
           END;'
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
    BASETYPE = INTEGER,
    STYPE    = TEXT,
    INITCOND = ''
);

/*
-- This is a temporary compatibility measure.
CREATE FUNCTION int_to_boolean(integer) RETURNS boolean
  AS 'select case when $1 = 0 then false else true end'
LANGUAGE 'sql' IMMUTABLE;

CREATE CAST (integer AS boolean)
  WITH FUNCTION int_to_boolean(integer) AS IMPLICIT;
*/