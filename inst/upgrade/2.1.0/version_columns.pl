#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

my $def = Bric::Config::DBD_TYPE eq 'mysql' ? ' NULL DEFAULT NULL' : '';
unless (test_column 'story_instance', 'priority') {
    # Update story_instance.
    do_sql (
        q{ ALTER TABLE story_instance ADD COLUMN primary_uri VARCHAR(128)},
        q{ ALTER TABLE story_instance ADD COLUMN priority    SMALLINT DEFAULT 3},
        qq{ALTER TABLE story_instance ADD COLUMN expire_date TIMESTAMP$def},
        q{ ALTER TABLE story_instance ADD COLUMN source__id  INTEGER},
        (Bric::Config::DBD_TYPE eq 'Pg' ?  q{
            UPDATE story_instance
               SET primary_uri = s.primary_uri,
                   priority    = s.priority,
                   expire_date = s.expire_date,
                   source__id  = s.source__id
              FROM story s
             WHERE s.id = story__id
        } : q{
            UPDATE story_instance si, story s
               SET si.primary_uri = s.primary_uri,
                   si.priority    = s.priority,
                   si.expire_date = s.expire_date,
                   si.source__id  = s.source__id
             WHERE s.id = si.story__id
        }),

        q{
            ALTER TABLE story_instance ADD CONSTRAINT ck_story_instance__priority
            CHECK (priority >= 1 AND priority <= 5)
        },

        (Bric::Config::DBD_TYPE eq 'Pg' ?  (
            q{ALTER TABLE story_instance ALTER priority SET NOT NULL},
            q{ALTER TABLE story_instance ALTER source__id SET NOT NULL},
            q{CREATE INDEX idx_story_instance__primary_uri ON story_instance(LOWER(primary_uri))},
        ) : (
            q{ALTER TABLE story_instance MODIFY priority SMALLINT NOT NULL DEFAULT 3},
            q{ALTER TABLE story_instance MODIFY source__id INTEGER NOT NULL},
            q{CREATE INDEX idx_story_instance__primary_uri ON story_instance(primary_uri(128))},
            q{ALTER TABLE story DROP FOREIGN KEY fk_source__story},
        )),

        q{CREATE INDEX fkx_story_instance__source__id ON story_instance(source__id)},

        q{ALTER TABLE story_instance
          ADD CONSTRAINT fk_source__story_instance FOREIGN KEY (source__id)
          REFERENCES source(id) ON DELETE RESTRICT},

        q{ALTER TABLE story DROP COLUMN primary_uri},
        q{ALTER TABLE story DROP COLUMN priority},
        q{ALTER TABLE story DROP COLUMN expire_date},
        q{ALTER TABLE story DROP COLUMN source__id},
    );

    if (Bric::Config::DBD_TYPE eq 'mysql') {
        do_sql(
            q{DROP TRIGGER ck_priority_alias_id_insert_story},
            q{DROP TRIGGER ck_priority_alias_id_update_story},

            q{CREATE TRIGGER ck_alias_id_insert_story BEFORE INSERT ON story
            FOR EACH ROW BEGIN
                IF (NEW.alias_id = NEW.id) THEN SET NEW.id = NULL; END IF;
            END;},

            q{CREATE TRIGGER ck_priority_insert_story_instance BEFORE INSERT ON story_instance
            FOR EACH ROW BEGIN
                IF (NEW.priority < 1 OR NEW.priority > 5) THEN SET NEW.priority = NULL; END IF;
            END;},

            q{CREATE TRIGGER ck_alias_id_update_story BEFORE UPDATE ON story
            FOR EACH ROW BEGIN
                IF (NEW.alias_id = NEW.id) THEN SET NEW.id = NULL; END IF;
            END;},

            q{CREATE TRIGGER ck_priority_update_story_instance BEFORE UPDATE ON story_instance
            FOR EACH ROW BEGIN
                IF (NEW.priority < 1 OR NEW.priority > 5) THEN SET NEW.priority = NULL; END IF;
            END;},
        );
    }
}

unless (test_column 'media_instance', 'priority') {
    # Update media_instance.
    do_sql (
        q{ ALTER TABLE media_instance ADD COLUMN priority    SMALLINT DEFAULT 3},
        qq{ALTER TABLE media_instance ADD COLUMN expire_date TIMESTAMP$def},
        q{ ALTER TABLE media_instance ADD COLUMN source__id  INTEGER},
        (Bric::Config::DBD_TYPE eq 'Pg' ?  q{
            UPDATE media_instance
               SET priority    = s.priority,
                   expire_date = s.expire_date,
                   source__id  = s.source__id
              FROM media s
             WHERE s.id = media__id
        } : q{
            UPDATE media_instance si, media s
               SET si.priority    = s.priority,
                   si.expire_date = s.expire_date,
                   si.source__id  = s.source__id
             WHERE s.id = si.media__id
        }),

        q{
            ALTER TABLE media_instance ADD CONSTRAINT ck_media_instance__priority
            CHECK (priority >= 1 AND priority <= 5)
        },

        (Bric::Config::DBD_TYPE eq 'Pg' ?  (
            q{ALTER TABLE media_instance ALTER priority SET NOT NULL},
            q{ALTER TABLE media_instance ALTER source__id SET NOT NULL},
        ) : (
            q{ALTER TABLE media_instance MODIFY priority SMALLINT NOT NULL DEFAULT 3},
            q{ALTER TABLE media_instance MODIFY source__id INTEGER NOT NULL},
            q{ALTER TABLE media DROP FOREIGN KEY fk_source__media},
        )),

        q{CREATE INDEX fkx_media_instance__source ON media_instance(source__id)},

        q{ALTER TABLE media_instance
          ADD CONSTRAINT fk_source__media_instance FOREIGN KEY (source__id)
          REFERENCES source(id) ON DELETE RESTRICT},

        q{ALTER TABLE media DROP COLUMN priority},
        q{ALTER TABLE media DROP COLUMN expire_date},
        q{ALTER TABLE media DROP COLUMN source__id},
    );

    if (Bric::Config::DBD_TYPE eq 'mysql') {
        do_sql(
            q{DROP TRIGGER ck_priority_alias_id_insert_media},
            q{DROP TRIGGER ck_priority_alias_id_update_media},

            q{CREATE TRIGGER ck_alias_id_insert_media BEFORE INSERT ON media
            FOR EACH ROW BEGIN
                IF (NEW.alias_id = NEW.id) THEN SET NEW.id = NULL; END IF;
            END;},

            q{CREATE TRIGGER ck_priority_insert_media_instance BEFORE INSERT ON media_instance
            FOR EACH ROW BEGIN
                IF (NEW.priority < 1 OR NEW.priority > 5) THEN SET NEW.priority = NULL; END IF;
            END;},

            q{CREATE TRIGGER ck_alias_id_update_media BEFORE UPDATE ON media
            FOR EACH ROW BEGIN
                IF (NEW.alias_id = NEW.id) THEN SET NEW.id = NULL; END IF;
            END;},

            q{CREATE TRIGGER ck_priority_update_media_instance BEFORE UPDATE ON media_instance
            FOR EACH ROW BEGIN
                IF (NEW.priority < 1 OR NEW.priority > 5) THEN SET NEW.priority = NULL; END IF;
            END;},
        );
    }
}

unless (test_column 'template_instance', 'priority') {
    # Update template_instance.
    do_sql (
        q{ ALTER TABLE template_instance ADD COLUMN name         VARCHAR(256)},
        q{ ALTER TABLE template_instance ADD COLUMN description  VARCHAR(1024)},
        q{ ALTER TABLE template_instance ADD COLUMN priority     SMALLINT DEFAULT 3},
        q{ ALTER TABLE template_instance ADD COLUMN category__id INTEGER},
        qq{ALTER TABLE template_instance ADD COLUMN expire_date  TIMESTAMP$def},

        (Bric::Config::DBD_TYPE eq 'Pg' ?  q{
            UPDATE template_instance
               SET name         = s.name,
                   description  = s.description,
                   priority     = s.priority,
                   category__id = s.category__id,
                   expire_date  = s.expire_date
              FROM template s
             WHERE s.id = template__id
        } : q{
            UPDATE template_instance si, template s
               SET si.name         = s.name,
                   si.description  = s.description,
                   si.priority     = s.priority,
                   si.category__id = s.category__id,
                   si.expire_date  = s.expire_date
             WHERE s.id = si.template__id
        }),

        q{
            ALTER TABLE template_instance ADD CONSTRAINT ck_template_instance__priority
            CHECK (priority >= 1 AND priority <= 5)
        },

        (Bric::Config::DBD_TYPE eq 'Pg' ?  (
            q{ALTER TABLE template_instance ALTER priority SET NOT NULL},
            q{CREATE INDEX idx_template_instance__name ON template_instance(LOWER(name))},
        ) : (
            q{ALTER TABLE media_instance MODIFY priority SMALLINT NOT NULL DEFAULT 3},
            q{CREATE INDEX idx_template_instance__name ON template_instance(name(254))},
            q{ALTER TABLE template DROP FOREIGN KEY fk_category__template},
        )),

        q{CREATE INDEX fkx_template_instance_category ON template_instance(category__id)},

        q{ALTER TABLE template_instance
          ADD CONSTRAINT fk_category__template_instance FOREIGN KEY (category__id)
          REFERENCES category(id) ON DELETE RESTRICT},

        q{ALTER TABLE template DROP COLUMN name},
        q{ALTER TABLE template DROP COLUMN description},
        q{ALTER TABLE template DROP COLUMN priority},
        q{ALTER TABLE template DROP COLUMN category__id},
        q{ALTER TABLE template DROP COLUMN expire_date},
    );

    if (Bric::Config::DBD_TYPE eq 'mysql') {
         do_sql(
             q{DROP TRIGGER ck_priority_tplate_type_insert_template},
             q{DROP TRIGGER ck_priority_tplate_type_update_template},

             q{CREATE TRIGGER ck_priority_insert_template_instance BEFORE INSERT ON template_instance
             FOR EACH ROW BEGIN
                 IF (NEW.priority < 1 OR NEW.priority > 5) THEN SET NEW.priority = NULL; END IF;
             END;},

             q{CREATE TRIGGER ck_tplate_type_insert_template BEFORE INSERT ON template
             FOR EACH ROW BEGIN
                 IF (NEW.tplate_type <> 1 AND NEW.tplate_type <> 2 AND NEW.tplate_type <> 3) THEN
                     SET NEW.tplate_type = NULL;
                 END IF;
             END;},

             q{CREATE TRIGGER ck_priority_update_template_instance BEFORE UPDATE ON template_instance
             FOR EACH ROW BEGIN
                 IF (NEW.priority < 1 OR NEW.priority > 5) THEN SET NEW.priority = NULL; END IF;
             END;},

             q{CREATE TRIGGER ck_tplate_type_update_template BEFORE UPDATE ON template
             FOR EACH ROW BEGIN
                 IF (NEW.tplate_type <> 1 AND NEW.tplate_type <> 2 AND NEW.tplate_type <> 3) THEN
                     SET NEW.tplate_type = NULL;
                 END IF;
             END;},
        );
     }
}
