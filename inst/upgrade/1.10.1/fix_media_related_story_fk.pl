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
        ALTER TABLE media_element
        DROP CONSTRAINT fk_media_element__related_story
    },
    q{
        ALTER TABLE media_element
        ADD CONSTRAINT fk_media_element__related_story
        FOREIGN KEY (related_story__id)
        REFERENCES story(id) ON DELETE CASCADE
    },
;
