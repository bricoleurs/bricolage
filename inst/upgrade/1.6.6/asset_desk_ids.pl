#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# This script fixes an issue where assets had their "desk_id" attribute
# set even though they were no longer on desks.

do_sql
  map { "UPDATE $_ SET desk__id = NULL
         WHERE id NOT IN (
                  SELECT am.object_id
                  FROM   desk d, member m, $_\_member am
                  WHERE  d.asset_grp = m.grp__id
                         AND m.id = am.member__id
                )"
    } qw(story media formatting)
  ;

__END__
