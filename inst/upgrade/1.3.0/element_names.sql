/* This script updates a few tables where the column for the element
   name was too small (32 characters rather than 64).  Due to the
   limitations of PostgreSQL this is not nearly as easy as it should
   be. I could use the temp table switch technique here:

      http://techdocs.postgresql.org/techdocs/updatingcolumns.php 

   Except that these tables have referential constraints on them from
   other tables.  The best I could come up with is to rename the old
   column and move the data into a new column of the correct type and
   old name.  

*/

ALTER TABLE story_container_tile RENAME name TO __name__old__;
ALTER TABLE story_container_tile ADD name VARCHAR(64);
UPDATE story_container_tile SET name = __name__old__;

ALTER TABLE media_container_tile RENAME name TO __name__old__;
ALTER TABLE media_container_tile ADD name VARCHAR(64);
UPDATE media_container_tile SET name = __name__old__;

ALTER TABLE story_data_tile RENAME name TO __name__old__;
ALTER TABLE story_data_tile ADD name VARCHAR(64);
UPDATE story_data_tile SET name = __name__old__;

ALTER TABLE media_data_tile RENAME name TO __name__old__;
ALTER TABLE media_data_tile ADD name VARCHAR(64);
UPDATE media_data_tile SET name = __name__old__;
