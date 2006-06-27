-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate: 2006-03-18 03:10:10 +0200 (Sat, 18 Mar 2006) $
-- Target DBMS: MySQL 5.0.22
-- Author: Arsu Andrei <acidburn@asynet.ro>
--
-- Description: This creates the triggers to replace the check constraints until checks
-- are supported in MySQL.
--
--


DELIMITER |

CREATE TRIGGER ck_priority_tries_insert_job BEFORE INSERT ON job
    FOR EACH ROW 
	BEGIN
	    IF ((NEW.priority < 1) OR (NEW.priority > 5))
	        THEN SET NEW.priority=NULL;
		END IF;        
    	    IF ((NEW.tries < 0) OR (NEW.tries > 10))
	        THEN SET NEW.tries=NULL;
		END IF;        
        END;
|

CREATE TRIGGER ck_priority_tries_update_job BEFORE UPDATE ON job
    FOR EACH ROW 
	BEGIN
	    IF ((NEW.priority < 1) OR (NEW.priority > 5))
	        THEN SET NEW.priority=NULL;
		END IF;        
    	    IF ((NEW.tries < 0) OR (NEW.tries > 10))
	        THEN SET NEW.tries=NULL;
		END IF;        
        END;
|

DELIMITER ;
