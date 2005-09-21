#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if test_table 'story_element';

do_sql
    # Drop constraints.
    q{ALTER TABLE story_container_tile DROP CONSTRAINT fk_sc_tile__sc_tile},
    q{ALTER TABLE story_container_tile DROP CONSTRAINT fk_story__sc_tile},
    q{ALTER TABLE story_container_tile DROP CONSTRAINT fk_sc_tile__related_story},
    q{ALTER TABLE story_container_tile DROP CONSTRAINT fk_sc_tile__related_media},
    q{ALTER TABLE story_container_tile DROP CONSTRAINT fk_sc_tile__element_type},

    q{ALTER TABLE media_container_tile DROP CONSTRAINT fk_mc_tile__mc_tile},
    q{ALTER TABLE media_container_tile DROP CONSTRAINT fk_media__mc_tile},
    q{ALTER TABLE media_container_tile DROP CONSTRAINT fk_mc_tile__related_story},
    q{ALTER TABLE media_container_tile DROP CONSTRAINT fk_mc_tile__related_media},
    q{ALTER TABLE media_container_tile DROP CONSTRAINT fk_mc_tile__element_type},

    q{ALTER TABLE story_data_tile DROP CONSTRAINT fk_story_instance__sd_tile},
    q{ALTER TABLE story_data_tile DROP CONSTRAINT fk_sc_tile__sd_tile},
    q{ALTER TABLE story_data_tile DROP CONSTRAINT fk_field_type__story_field},

    q{ALTER TABLE media_data_tile DROP CONSTRAINT fk_media_instance__md_tile},
    q{ALTER TABLE media_data_tile DROP CONSTRAINT fk_mc_tile__md_tile},
    q{ALTER TABLE media_data_tile DROP CONSTRAINT fk_field_type__media_field},

    # Drop indexes
    q{DROP INDEX fkx_story_instance__sd_tile},
    q{DROP INDEX fkx_field_type__story_field},
    q{DROP INDEX fkx_sc_tile__sd_tile},
    q{DROP INDEX fkx_media_instance__md_tile},
    q{DROP INDEX fkx_field_type__media_field},
    q{DROP INDEX fkx_sc_tile__md_tile},
    q{DROP INDEX fkx_sc_tile__sc_tile},
    q{DROP INDEX fkx_story__sc_tile},
    q{DROP INDEX fkx_sc_tile__related_story},
    q{DROP INDEX fkx_sc_tile__related_media},
    q{DROP INDEX fkx_sc_tile__element_type},
    q{DROP INDEX fkx_mc_tile__mc_tile},
    q{DROP INDEX fkx_media__mc_tile},
    q{DROP INDEX fkx_mc_tile__related_story},
    q{DROP INDEX fkx_mc_tile__related_media},
    q{DROP INDEX fkx_mc_tile__element_type},

    # Rename sequences.
    q{ALTER TABLE seq_story_container_tile RENAME TO seq_story_element},
    q{ALTER TABLE seq_media_container_tile RENAME TO seq_media_element},
    q{ALTER TABLE seq_story_data_tile RENAME TO seq_story_field},
    q{ALTER TABLE seq_media_data_tile RENAME TO seq_media_field},

    # Rename tables and PK defaults and constraints.
    q{ALTER TABLE story_container_tile RENAME TO story_element},
    q{ALTER TABLE story_element ALTER COLUMN id
      SET DEFAULT NEXTVAL('seq_story_element')},
    q{ALTER TABLE story_element DROP CONSTRAINT pk_container_tile__id},
    q{ALTER TABLE story_element ADD CONSTRAINT pk_story_element__id PRIMARY KEY (id)},

    q{ALTER TABLE media_container_tile RENAME TO media_element},
    q{ALTER TABLE media_element ALTER COLUMN id
      SET DEFAULT NEXTVAL('seq_media_element')},
    q{ALTER TABLE media_element DROP CONSTRAINT pk_media_container_tile__id},
    q{ALTER TABLE media_element ADD CONSTRAINT pk_media_element__id PRIMARY KEY (id)},

    q{ALTER TABLE story_data_tile RENAME TO story_field},
    q{ALTER TABLE story_field ALTER COLUMN id
      SET DEFAULT NEXTVAL('seq_story_field')},
    q{ALTER TABLE story_field DROP CONSTRAINT pk_story_data_tile__id},
    q{ALTER TABLE story_field ADD CONSTRAINT pk_story_field__id PRIMARY KEY (id)},

    q{ALTER TABLE media_data_tile RENAME TO media_field},
    q{ALTER TABLE media_field ALTER COLUMN id
      SET DEFAULT NEXTVAL('seq_media_field')},
    q{ALTER TABLE media_field DROP CONSTRAINT pk_media_data_tile__id},
    q{ALTER TABLE media_field ADD CONSTRAINT pk_media_field__id PRIMARY KEY (id)},

    # Recreate constraints.
    q{ALTER TABLE story_element
      ADD CONSTRAINT fk_story_element__story_element FOREIGN KEY (parent_id)
      REFERENCES story_element(id) ON DELETE CASCADE},

    q{ALTER TABLE story_element
      ADD CONSTRAINT fk_story__story_element FOREIGN KEY (object_instance_id)
      REFERENCES story_instance(id) ON DELETE CASCADE},

    q{ALTER TABLE story_element
      ADD CONSTRAINT fk_story_element__related_story FOREIGN KEY (related_story__id)
      REFERENCES story(id) ON DELETE CASCADE},

    q{ALTER TABLE story_element
      ADD CONSTRAINT fk_story_element__related_media FOREIGN KEY (related_media__id)
      REFERENCES media(id) ON DELETE CASCADE},

    q{ALTER TABLE story_element
      ADD CONSTRAINT fk_story_element__element_type FOREIGN KEY (element_type__id)
      REFERENCES element_type(id) ON DELETE RESTRICT},

    q{ALTER TABLE media_element
      ADD CONSTRAINT fk_media_element__media_element FOREIGN KEY (parent_id)
      REFERENCES media_element(id) ON DELETE CASCADE},

    q{ALTER TABLE media_element
      ADD CONSTRAINT fk_media__media_element FOREIGN KEY (object_instance_id)
      REFERENCES media_instance(id) ON DELETE CASCADE},

    q{ALTER TABLE media_element
      ADD CONSTRAINT fk_media_element__related_story FOREIGN KEY (related_story__id)
      REFERENCES story(id) ON DELETE CASCADE},

    q{ALTER TABLE media_element
      ADD CONSTRAINT fk_media_element__related_media FOREIGN KEY (related_media__id)
      REFERENCES media(id) ON DELETE CASCADE},

    q{ALTER TABLE media_element
      ADD CONSTRAINT fk_media_element__element_type FOREIGN KEY (element_type__id)
      REFERENCES element_type(id) ON DELETE RESTRICT},

    q{ALTER TABLE story_field
      ADD CONSTRAINT fk_story_instance__story_field FOREIGN KEY (object_instance_id)
      REFERENCES story_instance(id) ON DELETE CASCADE},

    q{ALTER TABLE story_field
      ADD CONSTRAINT fk_story_element__story_field FOREIGN KEY (parent_id)
      REFERENCES story_element(id) ON DELETE CASCADE},

    q{ALTER TABLE story_field
      ADD CONSTRAINT fk_field_type__story_field FOREIGN KEY (field_type__id)
      REFERENCES field_type(id) ON DELETE RESTRICT},

    q{ALTER TABLE media_field
      ADD CONSTRAINT fk_media_instance__media_field FOREIGN KEY (object_instance_id)
      REFERENCES media_instance(id) ON DELETE CASCADE},

    q{ALTER TABLE media_field
      ADD CONSTRAINT fk_media_element__media_field FOREIGN KEY (parent_id)
      REFERENCES media_element(id) ON DELETE CASCADE},

    q{ALTER TABLE media_field
      ADD CONSTRAINT fk_field_type__media_field FOREIGN KEY (field_type__id)
      REFERENCES field_type(id) ON DELETE RESTRICT},

    # Recreate indexes.
    q{CREATE INDEX fkx_story_instance__story_field ON story_field(object_instance_id)},
    q{CREATE INDEX fkx_field_type__story_field ON story_field(field_type__id)},
    q{CREATE INDEX fkx_sc_tile__story_field ON story_field(parent_id)},


    q{CREATE INDEX fkx_media_instance__media_field ON media_field(object_instance_id)},
    q{CREATE INDEX fkx_field_type__media_field ON media_field(field_type__id)},
    q{CREATE INDEX fkx_sc_tile__media_field ON media_field(parent_id)},

    q{CREATE INDEX fkx_story_element__story_element ON story_element(parent_id)},
    q{CREATE INDEX fkx_story__story_element ON story_element(object_instance_id)},
    q{CREATE INDEX fkx_story_element__related_story ON story_element(related_story__id)},
    q{CREATE INDEX fkx_story_element__related_media ON story_element(related_media__id)},
    q{CREATE INDEX fkx_story_element__element_type ON story_element(element_type__id)},

    q{CREATE INDEX fkx_media_element__media_element ON media_element(parent_id)},
    q{CREATE INDEX fkx_media__media_element ON media_element(object_instance_id)},
    q{CREATE INDEX fkx_media_element__related_story ON media_element(related_story__id)},
    q{CREATE INDEX fkx_media_element__related_media ON media_element(related_media__id)},
    q{CREATE INDEX fkx_media_element__element_type ON media_element(element_type__id)},

;
