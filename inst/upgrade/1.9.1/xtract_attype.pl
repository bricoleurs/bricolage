#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if test_column 'element_type', 'paginated';

do_sql
    q{ALTER TABLE element_type
      ADD COLUMN  top_level       BOOLEAN DEFAULT FALSE,
      ADD COLUMN  paginated       BOOLEAN DEFAULT FALSE,
      ADD COLUMN  fixed_uri       BOOLEAN DEFAULT FALSE,
      ADD COLUMN  related_story   BOOLEAN DEFAULT FALSE,
      ADD COLUMN  related_media   BOOLEAN DEFAULT FALSE,
      ADD COLUMN  media           BOOLEAN DEFAULT FALSE,
      ADD COLUMN  biz_class__id   INTEGER
    },

    q{ CREATE INDEX fkx_class__element_type ON element_type(biz_class__id) },
;

1;
__END__
