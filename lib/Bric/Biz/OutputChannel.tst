-- -----------------------------------------------------------------------------
-- OutputChannel.tst
--
-- VERSION: $Revision: 1.2 $
--
-- Test values.
--

DELETE FROM output_channel WHERE id IN (2, 3, 4);

INSERT INTO output_channel (id,name,description,pre_path,post_path,filename, file_ext, primary_ce)
VALUES (2, 'Email', 'Output in Email format', '', 'email', 'index', 'html', 0);

INSERT INTO output_channel (id,name,description,pre_path,post_path,filename, file_ext, primary_ce)
VALUES (3, 'WAP', 'Ouput to WAP format', '', 'wap', 'index', 'html', 0);

INSERT INTO output_channel (id,name,description,pre_path,post_path,filename, file_ext, primary_ce)
VALUES (4, 'Print', 'Print version', '', 'print', 'index', 'html', 0);

-- Add 'em to the 'All Output Channels' Group.
INSERT INTO member (id, grp__id, class__id, active)
VALUES (802, 23, 21, 1);

INSERT INTO output_channel_member (id, object_id, member__id)
VALUES (2, 2, 802); 

INSERT INTO member (id, grp__id, class__id, active)
VALUES (803, 23, 21, 1);

INSERT INTO output_channel_member (id, object_id, member__id)
VALUES (3, 3, 803); 

INSERT INTO member (id, grp__id, class__id, active)
VALUES (804, 23, 21, 1);

INSERT INTO output_channel_member (id, object_id, member__id)
VALUES (4, 4, 804); 

