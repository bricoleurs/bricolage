#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

exit unless test_index 'udx_alert_type__usr__id__name';

do_sql
  # Drop the old index.
  q{DROP INDEX udx_alert_type__usr__id__name},

  # Add the new multicolumn lower function.
  q{CREATE   FUNCTION lower_text_num(TEXT, NUMERIC(10, 0))
    RETURNS  TEXT AS 'SELECT LOWER($1) || to_char($2, ''|FM9999999999'')'
    LANGUAGE 'sql'
    WITH     (isCachable)},

  # Create a new unique index.
  q{CREATE UNIQUE INDEX udx_alert_type__name__usr__id
    ON alert_type(lower_text_num(name, usr__id))},
  ;

1;
__END__
