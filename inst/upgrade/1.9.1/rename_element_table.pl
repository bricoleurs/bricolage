#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if test_table 'element_type';

do_sql
    ##########################################################################
    # Rename Existing element type crap
    q{ALTER TABLE seq_element_type_member RENAME TO seq_at_type_member},
    q{ALTER TABLE element_type_member RENAME TO at_type_member},
    q{ALTER TABLE at_type_member ALTER COLUMN id
      SET DEFAULT NEXTVAL('seq_at_type_member')},
    q{ALTER TABLE at_type_member DROP CONSTRAINT pk_element_type_member__id},
    q{ALTER TABLE at_type_member ADD CONSTRAINT pk_at_type_member__id PRIMARY KEY (id)},
    q{DROP INDEX fkx_comp_type__comp_type_member},
    q{CREATE INDEX fkx_at_type__at_type_member ON at_type_member(object_id)},
    q{DROP INDEX fkx_member__comp_type_member},
    q{CREATE INDEX fkx_member__at_type_member ON at_type_member(member__id)},

    # Rename its constraints.
    q{ALTER TABLE at_type_member DROP CONSTRAINT fk_comp_type__comp_type_member},
    q{ALTER TABLE at_type_member DROP CONSTRAINT fk_member__comp_type_member},

    q{ALTER TABLE    at_type_member
      ADD CONSTRAINT fk_at_type__at_type_member FOREIGN KEY (object_id)
      REFERENCES     at_type(id) ON DELETE CASCADE},

    q{ALTER TABLE    at_type_member
      ADD CONSTRAINT fk_member__at_type_member FOREIGN KEY (member__id)
      REFERENCES     member(id) ON DELETE CASCADE},

    # Rename the sequences.
    q{ALTER TABLE seq_element RENAME TO seq_element_type},
    q{ALTER TABLE seq_element__output_channel
      RENAME TO seq_element_type__output_channel},
    q{ALTER TABLE seq_element_member RENAME TO seq_element_type_member},
    q{ALTER TABLE seq_attr_element RENAME TO seq_attr_element_type},
    q{ALTER TABLE seq_attr_element_val RENAME TO seq_attr_element_type_val},
    q{ALTER TABLE seq_attr_element_meta RENAME TO seq_attr_element_type_meta},
    q{ALTER TABLE seq_element__site RENAME TO seq_element_type__site},

    # Rename the table.
    q{ALTER TABLE element RENAME TO element_type},
    q{ALTER TABLE element_type ALTER COLUMN id
      SET DEFAULT NEXTVAL('seq_element_type')},
    q{ALTER TABLE element_type RENAME COLUMN at_grp__id TO et_grp__id},

    ##########################################################################
    # Drop any foreign keys and indexes so that we can rename the primary key.
    q{ALTER TABLE story DROP CONSTRAINT fk_element__story},
    q{DROP INDEX fdx_element__story},

    q{ALTER TABLE media DROP CONSTRAINT fk_element__media},
    q{DROP INDEX fkx_element__media},

    q{ALTER TABLE formatting DROP CONSTRAINT fk_element__formatting},
    q{DROP INDEX fkx_element__formatting},

    q{ALTER TABLE at_data DROP CONSTRAINT fk_element__at_data},
    q{DROP INDEX fkx_element__atd},
    q{DROP INDEX udx_atd__key_name__at_id},

    q{ALTER TABLE element__output_channel DROP CONSTRAINT fk_element__at_oc},
    q{ALTER TABLE element_member DROP CONSTRAINT fk_element__at_member},

    q{ALTER TABLE element__site drop CONSTRAINT fk_element__element__site__element__id},
    q{ALTER TABLE attr_element_val DROP CONSTRAINT fk_at__attr_at_val},

    # Rename the primary key.
    q{ALTER TABLE element_type DROP CONSTRAINT pk_element__id},
    q{ALTER TABLE element_type ADD CONSTRAINT pk_element_type__id PRIMARY KEY (id)},

    # Rename the foreign key columns.
    q{ALTER TABLE story RENAME COLUMN element__id TO element_type__id},
    q{ALTER TABLE media RENAME COLUMN element__id TO element_type__id},
    q{ALTER TABLE formatting RENAME COLUMN element__id TO element_type__id},
    q{ALTER TABLE at_data RENAME COLUMN element__id TO element_type__id},

    # Now restore the foreign keys and indexes with their new names.
    q{ALTER TABLE story
     ADD CONSTRAINT fk_element_type__story FOREIGN KEY (element_type__id)
     REFERENCES element_type(id) ON DELETE RESTRICT},
    q{CREATE INDEX fkx_element_type__story ON story(element_type__id)},

    q{ALTER TABLE media
     ADD CONSTRAINT fk_element_type__media FOREIGN KEY (element_type__id)
     REFERENCES element_type(id) ON DELETE RESTRICT},
    q{CREATE INDEX fkx_element_type__media ON media(element_type__id)},

    q{ALTER TABLE formatting
     ADD CONSTRAINT fk_element_type__formatting FOREIGN KEY (element_type__id)
     REFERENCES element_type(id) ON DELETE RESTRICT},
    q{CREATE INDEX fkx_element_type__formatting ON formatting(element_type__id)},

    q{ALTER TABLE at_data ADD
     CONSTRAINT fk_element_type__at_data FOREIGN KEY (element_type__id)
     REFERENCES element_type(id) ON DELETE CASCADE},
    q{CREATE UNIQUE INDEX udx_atd__key_name__et_id
      ON at_data(lower_text_num(key_name, element_type__id))},
    q{CREATE INDEX fkx_element_type__atd on at_data(element_type__id)},

    q{ALTER TABLE element_type DROP CONSTRAINT fk_grp__element},
    q{ALTER TABLE element_type
      ADD CONSTRAINT fk_grp__element_type FOREIGN KEY (et_grp__id)
      REFERENCES grp(id) ON DELETE CASCADE},

    q{ALTER TABLE ONLY element__site
      DROP CONSTRAINT fk_site__element__site__site__id},
    q{ALTER TABLE ONLY element__site
      ADD CONSTRAINT fk_site__et__site__site__id FOREIGN KEY (site__id)
      REFERENCES site(id) ON DELETE CASCADE},


    ##########################################################################
    # Rename element__site. Change the primary key first
    q{ALTER TABLE element__site DROP CONSTRAINT } . (
        test_primary_key('element__site', 'element__site_pkey')
            ? 'element__site_pkey'
            : 'pk_element__site__id'
    ),

    q{ALTER TABLE element__site RENAME TO element_type__site},
    q{ALTER TABLE element_type__site RENAME COLUMN element__id TO element_type__id},
    q{ALTER TABLE element_type__site ALTER COLUMN id
      SET DEFAULT NEXTVAL('seq_element_type__site')},

    q{ALTER TABLE element_type__site ADD CONSTRAINT pk_element_type__site__id
      PRIMARY KEY (id)},
    # Restore FK dropped above.
    q{ALTER TABLE element_type__site ADD
      CONSTRAINT fk_element_type__et__site__et__id FOREIGN KEY (element_type__id)
      REFERENCES element_type(id) ON DELETE CASCADE},

    # Rename element__output_channel.
    q{ALTER TABLE element__output_channel RENAME TO element_type__output_channel},
    q{ALTER TABLE element_type__output_channel
      RENAME COLUMN element__id TO element_type__id},
    q{ALTER TABLE element_type__output_channel ALTER COLUMN id
      SET DEFAULT NEXTVAL('seq_element_type__output_channel')},
    q{ALTER TABLE element_type__output_channel
      DROP CONSTRAINT pk_at__oc__id},
    q{ALTER TABLE element_type__output_channel
      ADD CONSTRAINT pk_element_type__output_channel__id
      PRIMARY KEY (id)},
    q{ALTER TABLE element_type__output_channel DROP CONSTRAINT fk_output_channel__at_oc},
    q{ALTER TABLE element_type__output_channel ADD
      CONSTRAINT fk_output_channel__et_oc FOREIGN KEY (output_channel__id)
      REFERENCES output_channel(id) ON DELETE CASCADE},
    # Restore FK dropped above.
    q{ALTER TABLE element_type__output_channel ADD
      CONSTRAINT fk_element_type__et_oc FOREIGN KEY (element_type__id)
      REFERENCES element_type(id) ON DELETE CASCADE},

    # Rename element_member
    q{ALTER TABLE element_member RENAME TO element_type_member},
    q{ALTER TABLE element_type_member ALTER COLUMN id
      SET DEFAULT NEXTVAL('seq_element_type_member')},
    q{ALTER TABLE element_type_member DROP CONSTRAINT pk_element_member__id},
    q{ALTER TABLE element_type_member ADD CONSTRAINT pk_element_type_member__id
      PRIMARY KEY (id)},

    # Restore FK dropped above.
    q{ALTER TABLE element_type_member ADD
      CONSTRAINT fk_element__et_member FOREIGN KEY (object_id)
      REFERENCES element_type(id) ON DELETE CASCADE},

    # Add constraint that never existed before (see pasto below).
    q{DELETE FROM element_type_member WHERE NOT EXISTS (
         SELECT id FROM member WHERE id = member__id limit 1
      )},
    q{ALTER TABLE element_type_member ADD
      CONSTRAINT fk_member__et_member FOREIGN KEY (member__id)
      REFERENCES member(id) ON DELETE CASCADE},

    # Drop bogus FK on category_member (pasto).
    q{ALTER TABLE category_member DROP CONSTRAINT fk_member__at_member},

    # Drop FKs the depend on attr_element.
    q{ALTER TABLE attr_element_val DROP CONSTRAINT fk_attr_at__attr_at_val},
    q{ALTER TABLE attr_element_meta DROP CONSTRAINT fk_attr_at__attr_at_meta},

    # Rename attr_element
    q{ALTER TABLE attr_element RENAME TO attr_element_type},
    q{ALTER TABLE attr_element_type ALTER COLUMN id
      SET DEFAULT NEXTVAL('seq_attr_element_type')},
    q{ALTER TABLE attr_element_type DROP CONSTRAINT pk_attr_element__id},
    q{ALTER TABLE attr_element_type ADD CONSTRAINT pk_attr_element_type__id
      PRIMARY KEY (id)},

    # Rename attr_element_val
    q{ALTER TABLE attr_element_val RENAME TO attr_element_type_val},
    q{ALTER TABLE attr_element_type_val ALTER COLUMN id
      SET DEFAULT NEXTVAL('seq_attr_element_type_val')},
    q{ALTER TABLE attr_element_type_val DROP CONSTRAINT pk_attr_element_val__id},
    q{ALTER TABLE attr_element_type_val ADD CONSTRAINT pk_attr_element_type_val__id
      PRIMARY KEY (id)},

    # Restore FKs dropped above.
    q{ALTER TABLE attr_element_type_val ADD
      CONSTRAINT fk_et__attr_et_val FOREIGN KEY (object__id)
      REFERENCES element_type(id) ON DELETE CASCADE},
    q{ALTER TABLE attr_element_type_val ADD
      CONSTRAINT fk_attr_et__attr_et_val FOREIGN KEY (attr__id)
      REFERENCES attr_element_type(id) ON DELETE CASCADE},

    # Rename attr_element_meta
    q{ALTER TABLE attr_element_meta RENAME TO attr_element_type_meta},
    q{ALTER TABLE attr_element_type_meta ALTER COLUMN id
      SET DEFAULT NEXTVAL('seq_attr_element_type_meta')},
    q{ALTER TABLE attr_element_type_meta DROP CONSTRAINT pk_attr_element_meta__id},
    q{ALTER TABLE attr_element_type_meta ADD CONSTRAINT pk_attr_element_type_meta__id
      PRIMARY KEY (id)},

    # Restore FK dropped above.
    q{ALTER TABLE attr_element_type_meta ADD
    CONSTRAINT fk_attr_et__attr_et_meta FOREIGN KEY (attr__id)
    REFERENCES attr_element_type(id) ON DELETE CASCADE},

    # Fix up element tables, which never had the FKs!
    q{ALTER TABLE story_container_tile RENAME COLUMN element__id TO element_type__id},
    q{DELETE FROM story_container_tile WHERE NOT EXISTS (
         SELECT id FROM element_type WHERE id = element_type__id limit 1
    )},
    q{CREATE INDEX fkx_sc_tile__element_type ON story_container_tile(element_type__id)},
    q{ALTER TABLE story_container_tile
      ADD CONSTRAINT fk_sc_tile__element_type FOREIGN KEY (element_type__id)
      REFERENCES element_type(id) ON DELETE CASCADE},

    q{ALTER TABLE media_container_tile RENAME COLUMN element__id TO element_type__id},
    q{CREATE INDEX fkx_mc_tile__element_type ON media_container_tile(element_type__id)},
    q{DELETE FROM media_container_tile WHERE NOT EXISTS (
         SELECT id FROM element_type WHERE id = element_type__id limit 1
    )},
    q{ALTER TABLE media_container_tile
      ADD CONSTRAINT fk_mc_tile__element_type FOREIGN KEY (element_type__id)
      REFERENCES element_type(id) ON DELETE CASCADE},

    # Rename indexes.
    q{DROP INDEX udx_element__key_name},
    q{CREATE UNIQUE INDEX udx_element_type__key_name ON element_type(LOWER(key_name))},

    q{DROP INDEX fkx_at_type__element},
    q{CREATE INDEX fkx_et_type__element_type ON element_type(type__id)},

    q{DROP INDEX fkx_grp__element},
    q{CREATE INDEX fkx_grp__element_type ON element_type(et_grp__id)},

    q{DROP INDEX udx_at_oc_id__at__oc_id},
    q{CREATE UNIQUE INDEX udx_et_oc_id__et__oc_id ON element_type__output_channel(element_type__id, output_channel__id)},

    q{DROP INDEX fkx_output_channel__at_oc},
    q{CREATE INDEX fkx_output_channel__et_oc ON element_type__output_channel(output_channel__id)},

    q{DROP INDEX fkx_element__at_oc},
    q{CREATE INDEX fkx_element__et_oc ON element_type__output_channel(element_type__id)},

    q{DROP INDEX fkx_element__at_member},
    q{CREATE INDEX fkx_element_type__et_member ON element_type_member(object_id)},

    q{DROP INDEX fkx_member__at_member},
    q{CREATE INDEX fkx_member__et_member ON element_type_member(member__id)},

    q{DROP INDEX udx_attr_at__subsys__name},
    q{CREATE UNIQUE INDEX udx_attr_et__subsys__name ON attr_element_type(subsys, name)},

    q{DROP INDEX idx_attr_at__name},
    q{CREATE INDEX idx_attr_et__name ON attr_element_type(LOWER(name))},

    q{DROP INDEX idx_attr_at__subsys},
    q{CREATE INDEX idx_attr_et__subsys ON attr_element_type(LOWER(subsys))},

    q{DROP INDEX udx_attr_at_val__obj_attr},
    q{CREATE UNIQUE INDEX udx_attr_et_val__obj_attr ON attr_element_type_val (object__id, attr__id)},

    q{DROP INDEX fkx_at__attr_at_val},
    q{CREATE INDEX fkx_et__attr_et_val ON attr_element_type_val(object__id)},

    q{DROP INDEX fkx_attr_at__attr_at_val},
    q{CREATE INDEX fkx_attr_et__attr_et_val ON attr_element_type_val(attr__id)},

    q{DROP INDEX udx_attr_at_meta__attr_name},
    q{CREATE UNIQUE INDEX udx_attr_et_meta__attr_name ON attr_element_type_meta (attr__id, name)},

    q{DROP INDEX idx_attr_at_meta__name},
    q{CREATE INDEX idx_attr_et_meta__name ON attr_element_type_meta(LOWER(name))},

    q{DROP INDEX fkx_attr_at__attr_at_meta},
    q{CREATE INDEX fkx_attr_et__attr_et_meta ON attr_element_type_meta(attr__id)},

    q{DROP INDEX fkx_element__element__site__element__id},
    q{CREATE INDEX fkx_et__et__site__element_type__id ON element_type__site(element_type__id)},

    q{DROP INDEX fkx_site__element__site__site__id},
    q{CREATE INDEX fkx_site__et__site__site__id ON element_type__site(site__id)},

    q{DROP INDEX fkx_output_channel__element__site},
    q{CREATE INDEX fkx_output_channel__et__site ON element_type__site(primary_oc__id)},

    q{DROP INDEX udx_element__site},
    q{CREATE UNIQUE INDEX udx_element_type__site on element_type__site(element_type__id, site__id)},

    # This was was misnamed to begin with, so just change it now.
    q{DROP INDEX fdx_alias_id__media},
    q{CREATE INDEX fkx_alias_id__media ON media(alias_id)},
;
