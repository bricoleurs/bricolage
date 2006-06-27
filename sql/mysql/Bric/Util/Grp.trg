-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate: 2004-11-09 05:32:57 +0200 (Tue, 09 Nov 2004) $
-- Target DBMS: MySQL 5.0.22
-- Author: Arsu Andrei <acidburn@asynet.ro>
--
-- Description: This creates the triggers to replace the check constraints until checks
-- are supported in MySQL.
--
--

DELIMITER |

CREATE TRIGGER ck_parent_id_insert_grp BEFORE INSERT ON grp
    FOR EACH ROW 
	BEGIN
	    IF (NEW.parent_id <> NEW.id)
	        THEN SET NEW.id=NULL;
		END IF;        
    
        END;
|

CREATE TRIGGER ck_parent_id_update_grp BEFORE UPDATE ON grp
    FOR EACH ROW 
	BEGIN
	    IF (NEW.parent_id <> NEW.id)
	        THEN SET NEW.id=NULL;
		END IF;        
    
        END;
|

DELIMITER ;
