-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate: 2005-10-10 10:15:55 +0300 (Mon, 10 Oct 2005) $
-- Target DBMS: MySQL 5.0.22
-- Author: Arsu Andrei <acidburn@asynet.ro>
--
-- Description: This creates the triggers to replace the check constraints until checks
-- are supported in MySQL.
--
--

DELIMITER |

CREATE TRIGGER ck_priority_tplate_type_insert_template BEFORE INSERT ON template
    FOR EACH ROW 
	BEGIN
	    IF ((NEW.priority < 1) OR (NEW.priority > 5))
	        THEN SET NEW.priority=NULL;
		END IF;        
	    IF ((NEW.tplate_type <> 1) AND (NEW.tplate_type <> 2) AND (NEW.tplate_type <> 3))
	        THEN SET NEW.tplate_type=NULL;
		END IF;        		
        END;
|

CREATE TRIGGER ck_priority_tplate_type_update_template BEFORE UPDATE ON template
    FOR EACH ROW 
	BEGIN
	    IF ((NEW.priority < 1) OR (NEW.priority > 5))
	        THEN SET NEW.priority=NULL;
		END IF;        
	    IF ((NEW.tplate_type <> 1) AND (NEW.tplate_type <> 2) AND (NEW.tplate_type <> 3))
	        THEN SET NEW.tplate_type=NULL;
		END IF;        		
        END;
|

DELIMITER ;
