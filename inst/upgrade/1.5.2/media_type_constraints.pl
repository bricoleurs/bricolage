#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

# If this fails, then the correct constraints are in place.
exit unless test_sql "INSERT INTO media_type_member VALUES(-1, -1, -1)";

do_sql
  qq{DELETE FROM media_type_member WHERE id = -1},

  qq{ALTER TABLE    media_type_member
     ADD CONSTRAINT fk_media_type__media_type_member FOREIGN KEY (object_id)
     REFERENCES     media_type(id) ON DELETE CASCADE},

  qq{ALTER TABLE    media_type_member
     ADD CONSTRAINT fk_member__media_type_member FOREIGN KEY (member__id)
     REFERENCES     member(id) ON DELETE CASCADE},
;
