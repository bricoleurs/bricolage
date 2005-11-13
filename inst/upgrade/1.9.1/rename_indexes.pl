#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if test_index 'fkx_primary_oc__media_instance';

do_sql
    q{DROP INDEX fdx_primary_oc__media_instance},
    q{CREATE INDEX fkx_primary_oc__media_instance ON media_instance(primary_oc__id)},

    q{DROP INDEX fdx_media__desk__id},
    q{CREATE INDEX fkx_media__desk__id ON media(desk__id) WHERE desk__id > 0},
    q{DROP INDEX fdx_media__workflow__id},
    q{CREATE INDEX fkx_media__workflow__id ON media(workflow__id) WHERE workflow__id > 0},

    q{DROP INDEX fdx_usr__story},
    q{CREATE INDEX fkx_usr__story ON story(usr__id)},

    q{DROP INDEX fdx_source__story},
    q{CREATE INDEX fkx_source__story ON story(source__id)},

    (   test_index('fkx_site__story')    ? q{DROP INDEX fkx_site__story}
      : test_index('fdx_site_id__story') ? qq{DROP INDEX fdx_site_id__story}
      : ()
    ),

    q{CREATE INDEX fkx_site_id__story ON story(site__id)},
    q{DROP INDEX fdx_alias_id__story},
    q{CREATE INDEX fkx_alias_id__story ON story(alias_id)},

    q{DROP INDEX fdx_story__story_instance},
    q{CREATE INDEX fkx_story__story_instance ON story_instance(story__id)},

    q{DROP INDEX fdx_usr__story_instance},
    q{CREATE INDEX fkx_usr__story_instance ON story_instance(usr__id)},

    q{DROP INDEX fdx_primary_oc__story_instance},
    q{CREATE INDEX fkx_primary_oc__story_instance ON story_instance(primary_oc__id)},

    q{DROP INDEX fdx_story__desk__id},
    q{CREATE INDEX fkx_story__desk__id ON story(desk__id) WHERE desk__id > 0},

    q{DROP INDEX fdx_story__workflow__id},
    q{CREATE INDEX fkx_story__workflow__id ON story(workflow__id) WHERE workflow__id > 0},

    q{DROP INDEX fdx_formatting__desk__id},
    q{CREATE INDEX fkx_formatting__desk__id ON formatting(desk__id) WHERE desk__id > 0},

    q{DROP INDEX fdx_formatting__workflow__id},
    q{CREATE INDEX fkx_formatting__workflow__id ON formatting(workflow__id) WHERE workflow__id > 0},

    q{DROP INDEX fdx_class__at_type},
    q{CREATE INDEX fkx_class__at_type ON at_type(biz_class__id)},

    q{DROP INDEX fdx_contact__contact_value},
    q{CREATE INDEX fkx_contact__contact_value on contact_value(contact__id)},

    q{DROP INDEX fdx_person__person_org},
    q{CREATE INDEX fkx_person__person_org ON person_org(person__id)},

    q{DROP INDEX fdx_org__person_org},
    q{CREATE INDEX fkx_org__person_org ON person_org(org__id)},

;
