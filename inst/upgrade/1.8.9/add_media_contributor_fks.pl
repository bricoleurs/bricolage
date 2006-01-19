#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if test_foreign_key 'media__contributor', 'fk_media__media__contributor';

do_sql
    q{ DELETE FROM media__contributor
       WHERE member__id IN (
                 SELECT mc.member__id
                 FROM   media__contributor mc LEFT JOIN member m
                        ON (mc.member__id = m.id)
                 WHERE m.id IS NULL
             )
    },

    q{ DELETE FROM media__contributor
       WHERE media_instance__id IN (
                 SELECT mc.media_instance__id
                 FROM   media__contributor mc LEFT JOIN media_instance m
                        ON (mc.media_instance__id = m.id)
                 WHERE m.id IS NULL
             )
    },

    q{ ALTER TABLE media__contributor
       ADD CONSTRAINT fk_media__media__contributor FOREIGN KEY (media_instance__id)
           REFERENCES media_instance(id) ON DELETE CASCADE
    },

    q{ ALTER TABLE media__contributor
       ADD CONSTRAINT fk_member__media__contributor FOREIGN KEY (member__id)
           REFERENCES member(id) ON DELETE CASCADE},

    q{ CREATE INDEX fkx_media__media__contributor
       ON media__contributor(media_instance__id)
    },

    q{ CREATE INDEX fkx_member__media__contributor
       ON media__contributor(member__id)
    },

;

__END__
