#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if test_table 'field_type';

do_sql
    # Drop FK constraints.
    q{ALTER TABLE story_data_tile DROP CONSTRAINT fk_at_data__sd_tile},
    q{ALTER TABLE media_data_tile DROP CONSTRAINT fk_at_data__md_tile},
    q{ALTER TABLE at_data DROP CONSTRAINT fk_element_type__at_data},
    q{ALTER TABLE attr_at_data_val DROP CONSTRAINT fk_attr_atd__attr_atd_val},
    q{ALTER TABLE attr_at_data_val DROP CONSTRAINT fk_atd__attr_atd_val},
    q{ALTER TABLE attr_at_data_meta DROP CONSTRAINT fk_attr_atd__attr_atd_meta},

    # Drop indexes
    q{DROP INDEX fkx_element__sd_tile},
    q{DROP INDEX fkx_element__md_tile},
    q{DROP INDEX udx_attr_atd__subsys__name},
    q{DROP INDEX idx_attr_atd__name},
    q{DROP INDEX idx_attr_atd__subsys},
    q{DROP INDEX udx_attr_atd_val__obj_attr},
    q{DROP INDEX fkx_atd__attr_atd_val},
    q{DROP INDEX fkx_attr_atd__attr_atd_val},
    q{DROP INDEX udx_attr_atd_meta__attr_name},
    q{DROP INDEX idx_attr_atd_meta__name},
    q{DROP INDEX fkx_attr_atd__attr_atd_meta},
    q{DROP INDEX udx_atd__key_name__et_id},
    q{DROP INDEX udx_atd__name__at_id},
    q{DROP INDEX fkx_map_type__atd},
    q{DROP INDEX fkx_element_type__atd},

    # Rename sequences.
    q{ALTER TABLE seq_at_data RENAME TO seq_field_type},
    q{ALTER TABLE seq_attr_at_data RENAME TO seq_attr_field_type},
    q{ALTER TABLE seq_attr_at_data_val RENAME TO seq_attr_field_type_val},
    q{ALTER TABLE seq_attr_at_data_meta RENAME TO seq_attr_field_type_meta},

    # Rename tables and PK defaults and constraints.
    q{ALTER TABLE at_data RENAME TO field_type},
    q{ALTER TABLE field_type ALTER COLUMN id
      SET DEFAULT NEXTVAL('seq_field_type')},
    q{ALTER TABLE field_type DROP CONSTRAINT pk_at_data__id},
    q{ALTER TABLE field_type ADD CONSTRAINT pk_field_type__id PRIMARY KEY (id)},

    q{ALTER TABLE attr_at_data RENAME TO attr_field_type},
    q{ALTER TABLE attr_field_type ALTER COLUMN id
      SET DEFAULT NEXTVAL('seq_attr_field_type')},
    q{ALTER TABLE attr_field_type DROP CONSTRAINT pk_attr_at_data__id},
    q{ALTER TABLE attr_field_type ADD CONSTRAINT pk_attr_field_type__id PRIMARY KEY (id)},

    q{ALTER TABLE attr_at_data_val RENAME TO attr_field_type_val},
    q{ALTER TABLE attr_field_type_val ALTER COLUMN id
      SET DEFAULT NEXTVAL('seq_attr_field_type_val')},
    q{ALTER TABLE attr_field_type_val DROP CONSTRAINT pk_attr_at_data_val__id},
    q{ALTER TABLE attr_field_type_val ADD CONSTRAINT pk_attr_field_type_val__id PRIMARY KEY (id)},

    q{ALTER TABLE attr_at_data_meta RENAME TO attr_field_type_meta},
    q{ALTER TABLE attr_field_type_meta ALTER COLUMN id
      SET DEFAULT NEXTVAL('seq_attr_field_type_meta')},
    q{ALTER TABLE attr_field_type_meta DROP CONSTRAINT pk_attr_at_data_meta__id},
    q{ALTER TABLE attr_field_type_meta ADD CONSTRAINT pk_attr_field_type_meta__id PRIMARY KEY (id)},

    # Rename FK columns.
    q{ALTER TABLE story_data_tile
      RENAME COLUMN element_data__id TO field_type__id},

    q{ALTER TABLE media_data_tile
      RENAME COLUMN element_data__id TO field_type__id},

    # Recreate FK constraints.
    q{ALTER TABLE story_data_tile
      ADD CONSTRAINT fk_field_type__story_field FOREIGN KEY (field_type__id)
      REFERENCES field_type(id) ON DELETE RESTRICT},

    q{ALTER TABLE media_data_tile
      ADD CONSTRAINT fk_field_type__media_field FOREIGN KEY (field_type__id)
      REFERENCES field_type(id) ON DELETE RESTRICT},

    q{ALTER TABLE field_type ADD
      CONSTRAINT fk_element_type__field_type FOREIGN KEY (element_type__id)
      REFERENCES element_type(id) ON DELETE CASCADE},

    q{ALTER TABLE attr_field_type_val ADD
      CONSTRAINT fk_attr_field_type__attr_field_type_val FOREIGN KEY (attr__id)
      REFERENCES attr_field_type(id) ON DELETE CASCADE},

    q{ALTER TABLE attr_field_type_val ADD
      CONSTRAINT fk_field_type__attr_field_type_val FOREIGN KEY (object__id)
      REFERENCES field_type(id) ON DELETE CASCADE},

    q{ALTER TABLE attr_field_type_meta ADD
      CONSTRAINT fk_attr_field_type__attr_field_type_meta FOREIGN KEY (attr__id)
      REFERENCES attr_field_type(id) ON DELETE CASCADE},

    # Recreate indexes.
    q{CREATE INDEX fkx_field_type__story_field ON story_data_tile(field_type__id)},
    q{CREATE INDEX fkx_field_type__media_field ON media_data_tile(field_type__id)},
    q{CREATE UNIQUE INDEX udx_attr_field_type__subsys__name ON attr_field_type(subsys, name)},
    q{CREATE INDEX idx_attr_field_type__name ON attr_field_type(LOWER(name))},
    q{CREATE INDEX idx_attr_field_type__subsys ON attr_field_type(LOWER(subsys))},
    q{CREATE UNIQUE INDEX udx_attr_field_type_val__obj_attr ON attr_field_type_val (object__id, attr__id)},
    q{CREATE INDEX fkx_field_type__attr_field_type_val ON attr_field_type_val(object__id)},
    q{CREATE INDEX fkx_attr_field_type__attr_field_type_val ON attr_field_type_val(attr__id)},
    q{CREATE UNIQUE INDEX udx_attr_field_type_meta__attr_name ON attr_field_type_meta (attr__id, name)},
    q{CREATE INDEX idx_attr_field_type_meta__name ON attr_field_type_meta(LOWER(name))},
    q{CREATE INDEX fkx_attr_field_type__attr_field_type_meta ON attr_field_type_meta(attr__id)},
    q{CREATE UNIQUE INDEX udx_field_type__key_name__et_id ON field_type(lower_text_num(key_name, element_type__id))},
    q{CREATE INDEX idx_field_type__name__at_id ON field_type(LOWER(name))},
    q{CREATE INDEX fkx_map_type__field_type on field_type(map_type__id)},
    q{CREATE INDEX fkx_element_type__field_type on field_type(element_type__id)},

;
