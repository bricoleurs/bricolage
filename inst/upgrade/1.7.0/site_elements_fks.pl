#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if test_index 'udx_element__site';

do_sql
  q{CREATE UNIQUE INDEX udx_element__site on element__site(element__id, site__id)},

  q{ALTER TABLE element__site ADD
    CONSTRAINT fk_site__element__site__site__id FOREIGN KEY (site__id)
    REFERENCES site(id) ON DELETE CASCADE},

  q{ALTER TABLE element__site ADD
    CONSTRAINT fk_element__element__site__element__id  FOREIGN KEY (element__id)
    REFERENCES element(id) ON DELETE CASCADE},

  q{ALTER TABLE element__site ADD
    CONSTRAINT fk_output_channel__element__site FOREIGN KEY (primary_oc__id)
    REFERENCES output_channel(id) ON DELETE CASCADE},

  q{CREATE INDEX fkx_element__element__site__element__id ON element__site(element__id)},

  q{CREATE INDEX fkx_site__element__site__site__id ON element__site(site__id)},

  q{CREATE INDEX fkx_output_channel__element__site ON element__site(primary_oc__id)},
  ;

1;
__END__
