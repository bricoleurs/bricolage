-- Project: Bricolage
-- VERSION: $Revision: 1.1 $
--
-- $Date: 2002-05-27 16:45:51 $
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Mark Jaroski <mark@geekhive.net>
--
-- Usage: category_full_path(category_grp_id)
--
-- Returns the full path of a given category.
--
-- Thanks to David Hagan <hagand@who.int> for examples stored proceedures 
-- for building a tree structure from a recursively keyed table.
--
CREATE FUNCTION category_full_path(INT) RETURNS VARCHAR AS'
DECLARE v_category_grp_id ALIAS FOR $1
;
DECLARE tmp_record RECORD
;
DECLARE tmp_id VARCHAR
;
DECLARE tmp_code VARCHAR
;
BEGIN
    tmp_code:=''''
    ;
    SELECT INTO tmp_record 
                    category.id AS category_id,
                    category.directory AS directory,
                    grp.parent_id AS parent_id
    FROM        category, grp 
    WHERE       grp.id = v_category_grp_id
    AND         grp.id = category.category_grp_id
    ;
    IF NOT FOUND THEN
        RETURN ''''::varchar
        ;
    END IF
    ;
    IF tmp_record.category_id=0 THEN 
        RETURN tmp_record.directory
        ;
    END IF
    ;
    tmp_id:=category_full_path(tmp_record.parent_id)
    ;
    IF tmp_record.category_id<>0 THEN
        tmp_code:=tmp_id::varchar || '' '' || tmp_record.directory::varchar || ''''
    ;
    END IF
    ;
    RETURN tmp_code
    ;
END
;
' LANGUAGE 'plpgsql'
;

