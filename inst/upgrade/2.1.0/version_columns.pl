#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

unless (test_column 'story_instance', 'priority') {
    # Update story_instance.
    do_sql (
        q{ALTER TABLE story_instance ADD COLUMN primary_uri VARCHAR(128)},
        q{ALTER TABLE story_instance ADD COLUMN priority    SMALLINT},
        q{ALTER TABLE story_instance ADD COLUMN expire_date TIMESTAMP},
        q{ALTER TABLE story_instance ADD COLUMN source__id  INTEGER},
        q{
            UPDATE story_instance
               SET primary_uri = s.primary_uri,
                   priority    = s.priority,
                   expire_date = s.expire_date,
                   source__id  = s.source__id
              FROM story s
             WHERE s.id = story__id
        },

        q{
            ALTER TABLE story_instance ADD CONSTRAINT ck_story_instance__priority
            CHECK (priority >= 1 AND priority <= 5)
        },

        q{ALTER TABLE story_instance ALTER priority SET NOT NULL},
        q{ALTER TABLE story_instance ALTER source__id SET NOT NULL},

        q{CREATE INDEX idx_story_instance__primary_uri ON story_instance(LOWER(primary_uri))},
        q{CREATE INDEX fkx_story_instance__source__id ON story_instance(source__id)},

        q{ALTER TABLE story_instance
          ADD CONSTRAINT fk_source__story_instance FOREIGN KEY (source__id)
          REFERENCES source(id) ON DELETE RESTRICT},

        q{ALTER TABLE story DROP COLUMN primary_uri},
        q{ALTER TABLE story DROP COLUMN priority},
        q{ALTER TABLE story DROP COLUMN expire_date},
        q{ALTER TABLE story DROP COLUMN source__id},
    );
}

unless (test_column 'media_instance', 'priority') {
    # Update media_instance.
    do_sql (
        q{ALTER TABLE media_instance ADD COLUMN priority    SMALLINT},
        q{ALTER TABLE media_instance ADD COLUMN expire_date TIMESTAMP},
        q{ALTER TABLE media_instance ADD COLUMN source__id  INTEGER},
        q{
            UPDATE media_instance
               SET priority    = s.priority,
                   expire_date = s.expire_date,
                   source__id  = s.source__id
              FROM media s
             WHERE s.id = media__id
        },

        q{ALTER TABLE media_instance ALTER priority SET NOT NULL},
        q{ALTER TABLE media_instance ALTER source__id SET NOT NULL},
        q{CREATE INDEX fkx_media_instance__source ON media_instance(source__id)},

        q{ALTER TABLE media_instance
          ADD CONSTRAINT fk_source__media_instance FOREIGN KEY (source__id)
          REFERENCES source(id) ON DELETE RESTRICT},

        q{
            ALTER TABLE media_instance ADD CONSTRAINT ck_media_instance__priority
            CHECK (priority >= 1 AND priority <= 5)
        },

        q{ALTER TABLE media_instance ALTER priority SET NOT NULL},

        q{ALTER TABLE media DROP COLUMN priority},
        q{ALTER TABLE media DROP COLUMN expire_date},
        q{ALTER TABLE media DROP COLUMN source__id},
    );
}

unless (test_column 'template_instance', 'priority') {
    # Update template_instance.
    do_sql (
        q{ALTER TABLE template_instance ADD COLUMN name         VARCHAR(256)},
        q{ALTER TABLE template_instance ADD COLUMN description  VARCHAR(1024)},
        q{ALTER TABLE template_instance ADD COLUMN priority     SMALLINT},
        q{ALTER TABLE template_instance ADD COLUMN category__id INTEGER},
        q{ALTER TABLE template_instance ADD COLUMN expire_date  TIMESTAMP},

        q{
            UPDATE template_instance
               SET name         = s.name,
                   description  = s.description,
                   priority     = s.priority,
                   category__id = s.category__id,
                   expire_date  = s.expire_date
              FROM template s
             WHERE s.id = template__id
        },

        q{ALTER TABLE template_instance ALTER priority SET NOT NULL},

        q{CREATE INDEX idx_template_instance__name ON template_instance(LOWER(name))},
        q{CREATE INDEX fkx_template_instance_category ON template_instance(category__id)},

        q{
            ALTER TABLE template_instance ADD CONSTRAINT ck_template_instance__priority
            CHECK (priority >= 1 AND priority <= 5)
        },

        q{ALTER TABLE template_instance
          ADD CONSTRAINT fk_category__template_instance FOREIGN KEY (category__id)
          REFERENCES category(id) ON DELETE RESTRICT},

        q{ALTER TABLE template DROP COLUMN name},
        q{ALTER TABLE template DROP COLUMN description},
        q{ALTER TABLE template DROP COLUMN priority},
        q{ALTER TABLE template DROP COLUMN category__id},
        q{ALTER TABLE template DROP COLUMN expire_date},
    );
}
