#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

my ($aid, $uri, $ocname, $type, $rolled_back);

for $type (qw(story media)) {
    # Drop any existing table, since it is almost certainly broken due
    # to issues with an earlier set of upgrade scripts.
    do_sql "DROP TABLE $type\_uri" if test_table "$type\_uri";

    # Create the table.
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
