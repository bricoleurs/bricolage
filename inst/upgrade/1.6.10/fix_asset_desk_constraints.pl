#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if fetch_sql q{
        SELECT 1
        FROM   pg_class c, pg_constraint r
        WHERE  r.conrelid = c.oid
               AND c.relname = 'story'
               AND r.contype = 'f'
               AND r.conname = 'fk_desk__story'
};

my @sql;

for my $table (qw(story media formatting)) {
    push @sql,
      qq{ALTER TABLE $table
         ADD CONSTRAINT fk_desk__$table FOREIGN KEY (desk__id)
	 REFERENCES desk(id) ON DELETE SET NULL};
}

# Make it so.
do_sql @sql;

