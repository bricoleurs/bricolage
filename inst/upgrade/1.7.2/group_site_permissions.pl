#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# Exit if we've already done the work.
exit if fetch_sql 'SELECT 1 FROM grp_priv WHERE id = 54';

do_sql
  # Give Story Editors READ rights to all sites.
  q{INSERT INTO grp_priv (id, grp__id, value)
    VALUES(54, 7, 1)},

  q{INSERT INTO grp_priv__grp_member (grp_priv__id, grp__id)
    VALUES(54, 47)},

  # Give Media Producers READ rights to all sites.
  q{INSERT INTO grp_priv (id, grp__id, value)
    VALUES(55, 8, 1)},

  q{INSERT INTO grp_priv__grp_member (grp_priv__id, grp__id)
    VALUES(55, 47)},

  # Give Template Developers READ rights to all sites.
  q{INSERT INTO grp_priv (id, grp__id, value)
    VALUES(56, 9, 1)},

  q{INSERT INTO grp_priv__grp_member (grp_priv__id, grp__id)
    VALUES(56, 47)},
  ;

__END__
