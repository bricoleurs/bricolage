-- -----------------------------------------------------------------------------
-- Formatting.tst
--
-- VERSION: $Revision: 1.2 $
--
-- Test values.
--

DELETE FROM formatting   WHERE id IN (1,10,11,2,20,21,3,4,5);

-- -----------------------------------------------------------------------------
-- Column - Cat=science

INSERT INTO formatting (id, name, priority, description, usr__id, output_channel__id,
element__id, category__id, file_name, current_version, active)
VALUES (1, 'column', 4, 'A formatting Asset', NULL, 1, 2, 11, 
'/science/column.mc',0, 1);

INSERT INTO formatting_instance (id, formatting__id, version, usr__id, data)
VALUES (1, 1, 0, 1, 'print "hello";');

INSERT INTO member (id, grp__id, class__id, active)
VALUES (715, 33, 19, 1);

INSERT INTO formatting_member (id, object_id, member__id)
VALUES (1, 1, 715); 

-- -----------------------------------------------------------------------------
-- Column - Cat=material

INSERT INTO formatting (id, name, priority, description, usr__id, output_channel__id,
element__id, category__id, file_name, current_version, active)
VALUES (10, 'column', 2, 'FA for material science column', NULL, 1, 2, 12,
'/science/material/column.mc', 0, 1);

INSERT INTO formatting_instance (id, formatting__id, version, usr__id, data) 
VALUES (10, 10, 0, 1, 'print "hello";');

INSERT INTO member (id, grp__id, class__id, active)
VALUES (716, 33, 19, 1);

INSERT INTO formatting_member (id, object_id, member__id)
VALUES (10, 10, 716); 

-- -----------------------------------------------------------------------------
-- Column - Cat=physical


INSERT INTO formatting (id, name, priority, description, usr__id, output_channel__id,
element__id, category__id, file_name, current_version, active)
VALUES (11, 'column', 3, 'FA for physical science column', NULL, 1, 2, 13,
'/science/physical/column.mc', 0, 1);

INSERT INTO formatting_instance (id, formatting__id, version, usr__id, data) 
VALUES (11, 11, 0, 1, 'print "hello";');

INSERT INTO member (id, grp__id, class__id, active)
VALUES (717, 33, 19, 1);

INSERT INTO formatting_member (id, object_id, member__id)
VALUES (11, 11, 717); 

-- -----------------------------------------------------------------------------
-- Inset OC=email

INSERT INTO formatting (id, name, priority, description, usr__id, output_channel__id,
element__id, category__id, file_name, current_version, active)
VALUES (2, 'inset', 3, 'FA for email inset', NULL, 2, 6, 12,
'/science/material/email/inset.mc', 0, 1);

INSERT INTO formatting_instance (id, formatting__id, version, usr__id, data)
VALUES (2, 2, 0, 1, 'print "hello";');

INSERT INTO member (id, grp__id, class__id, active)
VALUES (718, 33, 19, 1);

INSERT INTO formatting_member (id, object_id, member__id)
VALUES (2, 2, 718); 

-- -----------------------------------------------------------------------------
-- Inset OC=wap

INSERT INTO formatting (id, name, priority, description, usr__id, output_channel__id,
element__id, category__id, file_name, current_version, active)
VALUES (20, 'inset', 5, 'FA for WAP inset', NULL, 3, 6, 12,
'/science/material/wap/inset.mc', 0, 1);

INSERT INTO formatting_instance (id, formatting__id, version, usr__id, data)
VALUES (20, 20, 0, 1, 'print "hello";');

INSERT INTO member (id, grp__id, class__id, active)
VALUES (719, 33, 19, 1);

INSERT INTO formatting_member (id, object_id, member__id)
VALUES (20, 20, 719); 

-- -----------------------------------------------------------------------------
-- Inset OC=print

INSERT INTO formatting (id, name, priority, description, usr__id, output_channel__id,
element__id, category__id, file_name, current_version, active)
VALUES (21, 'inset', 4, 'FA for print inset', NULL, 4, 6, 12,
'/science/material/print/inset.mc', 0, 1);

INSERT INTO formatting_instance (id, formatting__id, version, usr__id, data)
VALUES (21, 21, 0, 1, 'print "hello";');

INSERT INTO member (id, grp__id, class__id, active)
VALUES (720, 33, 19, 1);

INSERT INTO formatting_member (id, object_id, member__id)
VALUES (21, 21, 720); 