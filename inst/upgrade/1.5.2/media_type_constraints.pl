#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

exit if test_constraint 'media_type_member', 'fk_media_type__media_type_member';

do_sql
  qq{ALTER TABLE    media_type_member
     ADD CONSTRAINT fk_media_type__media_type_member FOREIGN KEY (object_id)
     REFERENCES     media_type(id) ON DELETE CASCADE},

  qq{ALTER TABLE    media_type_member
     ADD CONSTRAINT fk_member__media_type_member FOREIGN KEY (member__id)
     REFERENCES     member(id) ON DELETE CASCADE},
;
