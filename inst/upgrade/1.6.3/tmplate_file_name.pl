#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

exit if test_column 'formatting_instance', 'file_name';

do_sql
  q{ALTER TABLE formatting_instance ADD file_name TEXT},

  q{UPDATE formatting_instance
    SET    file_name = formatting.file_name
    FROM   formatting
    WHERE  formatting.id = formatting_instance.formatting__id}
  ;

1;
__END__
