#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if test_column 'job', 'priority', undef, 1;

my @alters = (
  q{ALTER TABLE job ALTER COLUMN class__id SET DEFAULT 0},
  q{ALTER TABLE job ALTER COLUMN priority SET DEFAULT 3},
  q{ALTER TABLE job ALTER COLUMN executing SET DEFAULT 0},
  q{ALTER TABLE job ALTER COLUMN failed SET DEFAULT 0},
);

my @cols = qw(class__id priority executing failed);

if (db_version ge '7.3') {
    # Yay, we can just alter and drop columns!
    push @alters,
      q{ALTER TABLE job drop pending},
      map { "ALTER TABLE job ALTER COLUMN $_ SET NOT NULL" } @cols;
    ;
} else {
    # We can at least drop the useless constraints.
    push @alters,
      q{ALTER TABLE job DROP CONSTRAINT ck_job__pending},
      q{DROP INDEX idx_job__pending};

    # We have to get a little bit trickier.
    for my $c (@cols) {
        push @alters,
          qq{LOCK TABLE job IN ACCESS EXCLUSIVE MODE},
            qq{UPDATE pg_attribute
               SET    attnotnull = 't'
               WHERE  attname='$c'
                      AND attrelid = (
                          SELECT oid
                          FROM   pg_class
                          WHERE  relkind='r'
                                 AND relname='job'
                       )}
            ;
    }
}

do_sql @alters;
