#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, updir, updir, 'lib';
use Bric::Util::DBI qw(:all);
use Bric::Biz::Asset::Business::Story;
use Bric::Biz::Asset::Business::Media;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

my ($aid, $uri, $ocname, $type, $rolled_back);

for $type (qw(story media)) {
    next if test_table "$type\_uri";

    # Create the table, indices, and constraints.
    do_sql
      qq{CREATE TABLE $type\_uri (
           $type\__id NUMERIC(10)    NOT NULL,
           site__id   NUMERIC(10)    NOT NULL,
           uri       TEXT            NOT NULL
      )},
      ;
}

1;
__END__
