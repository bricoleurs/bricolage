#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

# Just bail if the indexes and constraints have already been created.
exit if test_index 'fkx_keyword__keyword_member';

do_sql
  # Create the relevant indexes.
  qq{CREATE INDEX fkx_keyword__keyword_member ON keyword_member(object_id)},
  qq{CREATE INDEX fkx_member__keyword_member ON keyword_member(member__id)},

  # And finally, add the needed constraints.
  qq{ALTER TABLE    keyword_member
     ADD CONSTRAINT fk_keyword__keyword_member FOREIGN KEY (object_id)
     REFERENCES     keyword(id) ON DELETE CASCADE},

  qq{ALTER TABLE    keyword_member
     ADD CONSTRAINT fk_member__keyword_member FOREIGN KEY (member__id)
     REFERENCES     member(id) ON DELETE CASCADE},
;

__END__
