#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

do_sql
    q{
        ALTER TABLE template_instance
        DROP CONSTRAINT fk_usr__template_instance
    },
    q{
        ALTER TABLE template_instance
        ADD CONSTRAINT fk_usr__template_instance FOREIGN KEY (usr__id)
        REFERENCES usr(id) ON DELETE RESTRICT
    },

    q{
        ALTER TABLE story_instance
        DROP CONSTRAINT fk_usr__story_instance
    },
    q{
        ALTER TABLE story_instance
        ADD CONSTRAINT fk_usr__story_instance FOREIGN KEY (usr__id)
        REFERENCES usr(id) ON DELETE RESTRICT;
    },

    q{
        ALTER TABLE story_instance
        DROP CONSTRAINT fk_primary_oc__story_instance
    },
    q{
        ALTER TABLE story_instance
        ADD CONSTRAINT fk_primary_oc__story_instance FOREIGN KEY (primary_oc__id)
        REFERENCES output_channel(id) ON DELETE RESTRICT;
    },
;
