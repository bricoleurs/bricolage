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
