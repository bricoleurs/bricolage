#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

my @sql;

for my $table (qw(story media formatting)) {
    push @sql,
      # Drop the old desk__id and workflow__id indexes.
      qq{DROP INDEX fdx_$table\__desk__id},
      qq{DROP INDEX fdx_$table\__workflow__id},

      # Add a new desk__id partial index.
      qq{CREATE INDEX fdx_$table\__desk__id
         ON           $table(desk__id)
         WHERE        desk__id > 0
      },

      # Add a workflow__id partial index.
      qq{CREATE INDEX fdx_$table\__workflow__id
         ON           $table(workflow__id)
         WHERE         workflow__id > 0
      },
}

# Make it so.
do_sql @sql;

