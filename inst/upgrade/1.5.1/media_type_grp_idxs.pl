#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if test_index 'fkx_media_type__media_type_member';

do_sql
  # Create the indexes for media type member management.
  q{CREATE INDEX fkx_media_type__media_type_member ON media_type_member(object_id)},
  q{CREATE INDEX fkx_member__media_type_member ON media_type_member(member__id)},
  ;

1;
__END__

