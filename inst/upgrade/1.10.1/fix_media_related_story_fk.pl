#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# The 1.9.1 upgrade scripts inadvertently made this FK constraint point to
# media.id instead of story.id. Oops.

do_sql
    q{
        ALTER TABLE media_container_tile
        DROP CONSTRAINT fk_mc_tile__related_story
    },
    q{
        ALTER TABLE media_container_tile
        ADD CONSTRAINT fk_mc_tile__related_story
        FOREIGN KEY (related_story__id)
        REFERENCES story(id) ON DELETE CASCADE
    },
;
