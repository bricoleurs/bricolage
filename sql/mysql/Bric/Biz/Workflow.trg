-- Project: Bricolage
-- VERSION: $LastChangedRevision$
--
-- $LastChangedDate: 2004-11-19 10:55:15 +0200 (Fri, 19 Nov 2004) $
-- Target DBMS: MySQL 5.0.22
-- Author: Arsu Andrei <acidburn@asynet.ro>
--
-- Description: This creates the triggers to replace the check constraints until checks
-- are supported in MySQL.
--
--

DELIMITER |

CREATE TRIGGER ck_type_insert_workflow BEFORE INSERT ON workflow
    FOR EACH ROW 
	BEGIN
	    IF ((NEW.type <> 1) AND (NEW.type <> 2) AND (NEW.type <> 3))
	        THEN SET NEW.type=NULL;
		END IF;        
    
        END;
|

CREATE TRIGGER ck_type_update_workflow BEFORE UPDATE ON workflow
    FOR EACH ROW 
	BEGIN
	    IF ((NEW.type <> 1) AND (NEW.type <> 2) AND (NEW.type <> 3))
	        THEN SET NEW.type=NULL;
		END IF;        
    
        END;
|

DELIMITER ;
