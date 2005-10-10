#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit unless test_table 'formatting';


do_sql
    q{ALTER TABLE seq_formatting RENAME TO seq_template},
    q{ALTER TABLE seq_formatting_instance RENAME TO seq_template_instance},
    q{ALTER TABLE seq_formatting_member RENAME TO seq_template_member},

    # Drop foreign keys.
    q{ALTER TABLE formatting_instance DROP CONSTRAINT fk_formatting__frmt_instance},
    q{ALTER TABLE formatting_member DROP CONSTRAINT fk_frmt__frmt_member},

    q{ALTER TABLE formatting RENAME TO template},
    q{ALTER TABLE template ALTER COLUMN id
      SET DEFAULT NEXTVAL('seq_template')},
    q{ALTER TABLE template DROP CONSTRAINT pk_formatting__id},
    q{ALTER TABLE template ADD CONSTRAINT pk_template__id PRIMARY KEY (id)},
    q{ALTER TABLE template DROP CONSTRAINT ck_formatting___tplate_type},
    q{ALTER TABLE template ADD CONSTRAINT ck_template___tplate_type
      CHECK (tplate_type IN (1, 2, 3))},

    q{ALTER TABLE formatting_instance RENAME TO template_instance},
    q{ALTER TABLE template_instance ALTER COLUMN id
      SET DEFAULT NEXTVAL('seq_template_instance')},
    q{ALTER TABLE template_instance RENAME COLUMN formatting__id
      TO template__id},
    q{ALTER TABLE template_instance
      DROP CONSTRAINT pk_formatting_instance__id},
    q{ALTER TABLE template_instance
      ADD CONSTRAINT pk_template_instance__id PRIMARY KEY (id)},

    q{ALTER TABLE formatting_member RENAME TO template_member},
    q{ALTER TABLE template_member ALTER COLUMN id
      SET DEFAULT NEXTVAL('seq_template_member')},
    q{ALTER TABLE template_member
      DROP CONSTRAINT pk_formatting_member__id},
    q{ALTER TABLE template_member
      ADD CONSTRAINT pk_template_member__id PRIMARY KEY (id)},

    # Restore foreign keys.
    q{ALTER TABLE template_instance
      ADD CONSTRAINT fk_template__template_instance FOREIGN KEY (template__id)
      REFERENCES template(id) ON DELETE CASCADE},

    q{ALTER TABLE    template_member
      ADD CONSTRAINT fk_template__template_member FOREIGN KEY (object_id)
      REFERENCES     template(id) ON DELETE CASCADE},

    # Drop and re-add other constraints.
    q{ALTER TABLE template DROP CONSTRAINT fk_usr__formatting},
    q{ALTER TABLE template DROP CONSTRAINT fk_output_channel__formatting},
    q{ALTER TABLE template DROP CONSTRAINT fk_element_type__formatting},
    q{ALTER TABLE template DROP CONSTRAINT fk_category__formatting},
    q{ALTER TABLE template DROP CONSTRAINT fk_workflow__formatting},
    q{ALTER TABLE template DROP CONSTRAINT fk_site__formatting},
    q{ALTER TABLE template DROP CONSTRAINT fk_desk__formatting},
    q{ALTER TABLE template_instance DROP CONSTRAINT fk_usr__format_instance},
    q{ALTER TABLE template_member DROP CONSTRAINT fk_member__frmt_member},

    q{ALTER TABLE template
      ADD CONSTRAINT fk_usr__template FOREIGN KEY (usr__id)
      REFERENCES usr(id) ON DELETE RESTRICT},

    q{ALTER TABLE template
      ADD CONSTRAINT fk_output_channel__template FOREIGN KEY (output_channel__id)
      REFERENCES output_channel(id) ON DELETE RESTRICT},

    q{ALTER TABLE template
      ADD CONSTRAINT fk_element_type__template FOREIGN KEY (element_type__id)
      REFERENCES element_type(id) ON DELETE RESTRICT},

    q{ALTER TABLE template
      ADD CONSTRAINT fk_category__template FOREIGN KEY (category__id)
      REFERENCES category(id) ON DELETE RESTRICT},

    q{ALTER TABLE template
      ADD CONSTRAINT fk_workflow__template FOREIGN KEY (workflow__id)
      REFERENCES workflow(id) ON DELETE RESTRICT},

    q{ALTER TABLE template
      ADD CONSTRAINT fk_site__template FOREIGN KEY (site__id)
      REFERENCES site(id) ON DELETE RESTRICT},

    q{ALTER TABLE template
      ADD CONSTRAINT fk_desk__template FOREIGN KEY (desk__id)
      REFERENCES desk(id) ON DELETE RESTRICT},

    q{ALTER TABLE template_instance
      ADD CONSTRAINT fk_usr__template_instance FOREIGN KEY (usr__id)
      REFERENCES usr(id) ON DELETE SET NULL},

    q{ALTER TABLE    template_member
      ADD CONSTRAINT fk_member__template_member FOREIGN KEY (member__id)
      REFERENCES     member(id) ON DELETE CASCADE},

    # Drop and restor indexes.
    q{DROP INDEX idx_formatting__description},
    q{DROP INDEX idx_formatting__deploy_date},
    q{DROP INDEX udx_formatting__file_name__oc},
    q{DROP INDEX idx_formatting__name},
    q{DROP INDEX idx_formatting__file_name},
    q{DROP INDEX fkx_usr__formatting},
    q{DROP INDEX fkx_output_channel__formatting},
    q{DROP INDEX fkx_element_type__formatting},
    q{DROP INDEX fkx_category__formatting},
    q{DROP INDEX fkx_formatting__desk__id},
    q{DROP INDEX fkx_formatting__workflow__id},
    q{DROP INDEX fkx_site__formatting},
    q{DROP INDEX fkx_usr__formatting_instance},
    q{DROP INDEX fkx_formatting__frmt_instance},
    q{DROP INDEX idx_formatting_instance__note},
    q{DROP INDEX fkx_frmt__frmt_member},
    q{DROP INDEX fkx_member__frmt_member},

    q{CREATE UNIQUE INDEX udx_template__file_name__oc
      ON template(file_name, output_channel__id)},
    q{CREATE INDEX idx_template__name ON template(LOWER(name))},
    q{CREATE INDEX idx_template__file_name ON template(LOWER(file_name))},
    q{CREATE INDEX fkx_usr__template ON template(usr__id)},
    q{CREATE INDEX fkx_output_channel__template ON template(output_channel__id)},
    q{CREATE INDEX fkx_element_type__template ON template(element_type__id)},
    q{CREATE INDEX fkx_category__template ON template(category__id)},
    q{CREATE INDEX fkx_template__desk__id ON template(desk__id) WHERE desk__id > 0},
    q{CREATE INDEX fkx_template__workflow__id ON template(workflow__id) WHERE workflow__id > 0},
    q{CREATE INDEX fkx_site__template ON template(site__id)},

    q{CREATE INDEX fkx_usr__template_instance ON template_instance(usr__id)},
    q{CREATE INDEX fkx_template__tmpl_instance ON template_instance(template__id)},
    q{CREATE INDEX idx_template_instance__note ON template_instance(note) WHERE note IS NOT NULL},

    q{CREATE INDEX fkx_template__template_member ON template_member(object_id)},
    q{CREATE INDEX fkx_member__template_member ON template_member(member__id)},

    # Update class name.
    q{UPDATE class
      SET    key_name = 'template',
             pkg_name = 'Bric::Biz::Asset::Template'
      WHERE  key_name = 'formatting'
    },

    q{UPDATE class
      SET    key_name = 'template_grp',
             pkg_name = 'Bric::Util::Grp::Template'
      WHERE  key_name = 'formatting_grp'
    },

    q{UPDATE event_type
      SET    key_name = 'template_deploy'
      WHERE  key_name = 'formatting_deploy'
    },

    q{UPDATE event_type
      SET    key_name = 'template_redeploy'
      WHERE  key_name = 'formatting_redeploy'
    },

    q{UPDATE event_type
      SET    key_name = 'template_checkin'
      WHERE  key_name = 'formatting_checkin'
    },

    q{UPDATE event_type
      SET    key_name = 'template_moved'
      WHERE  key_name = 'formatting_moved'
    },

    q{UPDATE event_type
      SET    key_name = 'template_add_workflow'
      WHERE  key_name = 'formatting_add_workflow'
    },

    q{UPDATE event_type
      SET    key_name = 'template_rem_workflow'
      WHERE  key_name = 'formatting_rem_workflow'
    },

    q{UPDATE event_type
      SET    key_name = 'template_checkout'
      WHERE  key_name = 'formatting_checkout'
    },

    q{UPDATE event_type
      SET    key_name = 'template_cancel_checkout'
      WHERE  key_name = 'formatting_cancel_checkout'
    },

    q{UPDATE event_type
      SET    key_name = 'template_new'
      WHERE  key_name = 'formatting_new'
    },

    q{UPDATE event_type
      SET    key_name = 'template_save'
      WHERE  key_name = 'formatting_save'
    },

    q{UPDATE event_type
      SET    key_name = 'template_deact'
      WHERE  key_name = 'formatting_deact'
    },

    q{UPDATE event_type
      SET    key_name = 'template_edit_code'
      WHERE  key_name = 'formatting_edit_code'
    },

;

1;
__END__
