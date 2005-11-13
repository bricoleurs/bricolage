#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit unless test_column 'element_type', 'reference';

do_sql
    q{ UPDATE element_type
       SET    top_level     = at.top_level,
              paginated     = at.paginated,
              fixed_uri     = at.fixed_url,
              related_story = at.related_story,
              related_media = at.related_media,
              media         = at.media,
              biz_class__id = at.biz_class__id
       FROM   at_type as at
       WHERE  at.id = element_type.type__id
    },

    map ({ qq{ ALTER TABLE element_type $_ } }
       'ALTER COLUMN top_level     SET NOT NULL',
       'ALTER COLUMN paginated     SET NOT NULL',
       'ALTER COLUMN fixed_uri     SET NOT NULL',
       'ALTER COLUMN related_story SET NOT NULL',
       'ALTER COLUMN related_media SET NOT NULL',
       'ALTER COLUMN media         SET NOT NULL',
       'ALTER COLUMN biz_class__id SET NOT NULL',
       'ALTER COLUMN type__id      DROP NOT NULL',
       'DROP  COLUMN reference',
    ),

    q{ ALTER TABLE field_type DROP COLUMN publishable },

    q{ ALTER TABLE element_type ADD
	   CONSTRAINT fk_class__element_type FOREIGN KEY (biz_class__id)
	   REFERENCES class(id) ON DELETE CASCADE;
    },
;

1;
__END__
