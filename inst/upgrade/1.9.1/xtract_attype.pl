#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if test_column 'element_type', 'paginated';

do_sql
    map ({ qq{ALTER TABLE element_type $_ } }
      'ADD COLUMN   top_level     BOOLEAN',
      'ADD COLUMN   paginated     BOOLEAN',
      'ADD COLUMN   fixed_uri     BOOLEAN',
      'ADD COLUMN   related_story BOOLEAN',
      'ADD COLUMN   related_media BOOLEAN',
      'ADD COLUMN   media         BOOLEAN',
      'ADD COLUMN  biz_class__id INTEGER',
    ),

    q{ CREATE INDEX fkx_class__element_type ON element_type(biz_class__id) },
;

1;
__END__
