-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate: 2006-01-18 02:34:40 +0200 (Wed, 18 Jan 2006) $
-- Target DBMS: MySQL 5.0.22
-- Author: Arsu Andrei <acidburn@asynet.ro>
--
-- Description: This creates the triggers to replace the check constraints until checks
-- are supported in MySQL.
--
--


DELIMITER |

CREATE TRIGGER ck_priority_alias_id_insert_story BEFORE INSERT ON story
    FOR EACH ROW 
	BEGIN
	    IF ((NEW.priority < 1) OR (NEW.priority > 5))
	        THEN SET NEW.priority=NULL;
		END IF;        
    	    IF ((NEW.alias_id = NEW.id))
	        THEN SET NEW.id=NULL;
		END IF;        
        END;
|

CREATE TRIGGER ck_priority_alias_id_update_story BEFORE UPDATE ON story
    FOR EACH ROW 
	BEGIN
	    IF ((NEW.priority < 1) OR (NEW.priority > 5))
	        THEN SET NEW.priority=NULL;
		END IF;        
    	    IF ((NEW.alias_id = NEW.id))
	        THEN SET NEW.id=NULL;
		END IF;        
        END;
|

DELIMITER ;
