#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# Just bail if the site class has been added to the class table.
exit if test_index 'udx_site__name';

do_sql
  ############################################################################
  # Add the indices.
  qq{CREATE UNIQUE INDEX udx_site__name ON site(LOWER(name))},
  qq{CREATE UNIQUE INDEX udx_site__domain_name ON site(LOWER(domain_name))},
  qq{CREATE INDEX fkx_site__site_member ON site_member(object_id)},
  qq{CREATE INDEX fkx_member__site_member ON site_member(member__id)},
  qq{CREATE INDEX idx_grp__description ON grp(LOWER(description))},

  ############################################################################
  # And finally, add the constraints.
  qq{ALTER TABLE    site
     ADD CONSTRAINT fk_grp__site FOREIGN KEY (id)
     REFERENCES     grp(id) ON DELETE CASCADE},

  qq{ALTER TABLE    site_member
    ADD CONSTRAINT fk_site__site_member FOREIGN KEY (object_id)
    REFERENCES     site(id) ON DELETE CASCADE},

  qq{ALTER TABLE    site_member
     ADD CONSTRAINT fk_member__site_member FOREIGN KEY (member__id)
     REFERENCES     member(id) ON DELETE CASCADE},
  ;

1;
__END__
