#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

exit if fetch_sql "SELECT 1 FROM event_type where name = 'Contributor Type Field Added'";

do_sql
  q{UPDATE event_type
    SET    name = 'Contributor Type Field Added',
           description = 'A new field was added to the Contributor Type profile.'
    WHERE  key_name = 'contrib_type_ext'},

  q{UPDATE event_type
    SET    name = 'Contributor Type Field Deleted',
           description = 'A field was deleted from the Contributor Type profile.'
    WHERE  key_name = 'contrib_type_unext'},

  q{UPDATE event_type
    SET    name = 'Field Added to Element',
           description = 'A field was added to the element profile.'
    WHERE  key_name = 'element_attr_add'},

  q{UPDATE event_type
    SET    name = 'Field Deleted from Element',
           description = 'A field was deleted from the element profile.'
    WHERE  key_name = 'element_attr_del'},
  ;

1;
__END__
