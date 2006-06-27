--
-- Project: Bricolage API
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

CREATE TRIGGER ck_value_insert_grp_priv BEFORE INSERT ON grp_priv
    FOR EACH ROW 
	BEGIN
	    IF ((NEW.value < 1) OR (NEW.value > 255))
	        THEN SET NEW.value=NULL;
		END IF;        
    
        END;
|

CREATE TRIGGER ck_value_update_grp_priv BEFORE UPDATE ON grp_priv
    FOR EACH ROW 
	BEGIN
	    IF ((NEW.value < 1) OR (NEW.value > 255))
	        THEN SET NEW.value=NULL;
		END IF;        
    
        END;
|

DELIMITER ;
