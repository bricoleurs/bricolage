#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if test_column 'job', 'story_instance__id';

do_sql
    q{ALTER TABLE job RENAME COLUMN story__id TO story_instance__id},
    q{ALTER TABLE job RENAME COLUMN media__id TO media_instance__id},
    q{ALTER TABLE job DROP CONSTRAINT fk_job__story},
    q{ALTER TABLE job DROP CONSTRAINT fk_job__media},

    # Fix issue where some stories and media may not have the published_version
    # set, even though they've been published.
    q{UPDATE story
      SET    published_version = COALESCE(s.published_version, s.current_version),
             publish_status    = '1'
      FROM   job j, story s
      WHERE  story.id = s.id
             AND j.story__id = s.id
             AND (
                  s.published_version = null
                  OR s.publish_status = 0
             );
    },

    q{UPDATE media
      SET    published_version = COALESCE(m.published_version, m.current_version),
             publish_status    = '1'
      FROM   job j, media m
      WHERE  media.id = m.id
             AND j.media__id = m.id
             AND (
                  m.published_version = null
                  OR m.publish_status = 0
             );
    },

    q{UPDATE job
      SET    story_instance__id = si.id
      FROM   (
                 SELECT min(si2.id) AS id, story__id
                 FROM   story s, story_instance si2
                 WHERE  s.id = si2.story__id
                        AND s.published_version = si2.version
                 GROUP  BY si2.story__id
              ) AS si
      WHERE  story_instance__id = si.story__id
             AND story_instance__id IS NOT NULL
    },

    q{UPDATE job
      SET    media_instance__id = mi.id
      FROM   (
                 SELECT min(mi2.id) AS id, media__id
                 FROM   media s, media_instance mi2
                 WHERE  s.id = mi2.media__id
                        AND s.published_version = mi2.version
                 GROUP  BY mi2.media__id
              ) AS mi
      WHERE  media_instance__id = mi.media__id
             AND media_instance__id IS NOT NULL
    },

    q{ALTER TABLE job ADD CONSTRAINT fk_job__story_instance
      FOREIGN KEY (story_instance__id)
      REFERENCES story_instance(id) ON DELETE CASCADE
    },

    q{ALTER TABLE job ADD CONSTRAINT fk_job__media_instance
      FOREIGN KEY (media_instance__id)
      REFERENCES media_instance(id) ON DELETE CASCADE
    },

    q{CREATE INDEX fkx_story_instance__job ON job(story_instance__id)
      WHERE story_instance__id IS NOT NULL
    },

    q{CREATE INDEX fkx_media_instance__job ON job(media_instance__id)
     WHERE media_instance__id IS NOT NULL
    },
;
