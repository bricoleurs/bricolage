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

CREATE TRIGGER ck_uri_case_insert_output_channel BEFORE INSERT ON output_channel
    FOR EACH ROW 
	BEGIN
	    IF ((NEW.uri_case <> 1) AND (NEW.uri_case <> 2) AND (NEW.uri_case <> 3))
	        THEN SET NEW.uri_case=NULL;
		END IF;        
    
        END;
|

CREATE TRIGGER ck_uri_case_update_output_channel BEFORE UPDATE ON output_channel
    FOR EACH ROW 
	BEGIN
	    IF ((NEW.uri_case <> 1) AND (NEW.uri_case <> 2) AND (NEW.uri_case <> 3))
	        THEN SET NEW.uri_case=NULL;
		END IF;        
    
        END;
|

CREATE TRIGGER ck_include_oc_id_insert_output_channel_include BEFORE INSERT ON output_channel_include
    FOR EACH ROW 
	BEGIN
	    IF (NEW.include_oc_id <> output_channel__id)
		THEN SET NEW.include_oc_id=NULL;
	    END IF;        
        END;
|

CREATE TRIGGER ck_include_oc_id_update_output_channel_include BEFORE UPDATE ON output_channel_include
    FOR EACH ROW 
	BEGIN
	    IF (NEW.include_oc_id <> output_channel__id)
		THEN SET NEW.include_oc_id=NULL;
	    END IF;        
        END;
|

DELIMITER ;