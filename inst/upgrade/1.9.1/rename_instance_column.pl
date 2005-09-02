#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if test_column 'story_container_tile', 'related_story__id';

CREATE INDEX fkx_sc_tile__related_story ON story_container_tile(related_instance__id);

do_sql
    # Handle story.
    q{DROP INDEX fkx_sc_tile__related_story},
    q{
        ALTER TABLE story_container_tile
        DROP CONSTRAINT fk_sc_tile__related_story
    },

    q{
        ALTER TABLE story_container_tile
        RENAME related_instance__id TO related_story__id
    },

    q{
        CREATE INDEX fkx_sc_tile__related_story
        ON story_container_tile(related_story__id)
     },

    q{
        ALTER TABLE story_container_tile
        ADD CONSTRAINT fk_sc_tile__related_story
        FOREIGN KEY (related_story__id)
        REFERENCES story(id) ON DELETE CASCADE;
    },

    # Handle media--no preexisting constraint or index.
    q{
        ALTER TABLE media_container_tile
        RENAME related_instance__id TO related_story__id
    },

    q{
        CREATE INDEX fkx_mc_tile__related_story
        ON media_container_tile(related_story__id)
     },

    q{
        ALTER TABLE media_container_tile
        ADD CONSTRAINT fk_mc_tile__related_story
        FOREIGN KEY (related_story__id)
        REFERENCES media(id) ON DELETE CASCADE
    },

    # Add FK constraint for mediacontainer_tile.related_media__id
    q{
        CREATE INDEX fkx_mc_tile__related_media
        ON media_container_tile(related_media__id)
     },

    q{
        ALTER TABLE media_container_tile
        ADD CONSTRAINT fk_mc_tile__related_media
        FOREIGN KEY (related_media__id)
        REFERENCES media(id) ON DELETE CASCADE
    },
;
