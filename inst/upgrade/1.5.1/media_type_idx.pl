#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

do_sql
  "DROP INDEX udx_media_type_ext__extension",
  "CREATE UNIQUE INDEX udx_media_type_ext__extension " .
    "ON media_type_ext(LOWER(extension))"
  ;

__END__
