#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if fetch_sql q{
        SELECT 1
        FROM   pg_class c,
               pg_index i
        WHERE  i.indexrelid = c.oid
               and c.relname = 'fdx_story__workflow__id'
};

my @sql;

for my $table (qw(story media formatting)) {
    my $in = $table eq 'formatting' ? '' : '_instance';
    push @sql,
      # Drop the old desk__id index.
      qq{DROP INDEX fdx_$table\__desk__id},

      # Add a new desk__id partial index.
      qq{CREATE INDEX fdx_$table\__desk__id
         ON           $table(desk__id)
         WHERE        desk__id IS NOT NULL
      },

      # Add a workflow__id partial index.
      qq{CREATE INDEX fdx_$table\__workflow__id
         ON           $table(workflow__id)
         WHERE         workflow__id IS NOT NULL
      },

      # Add an index on the description column, since simple searches
      # use it. It's in the member table for story and media, but not
      # for formatting.
      qq{CREATE INDEX idx_$table$in\__description
         ON           $table$in(LOWER(description))
      };
}

# Make it so.
do_sql @sql;

