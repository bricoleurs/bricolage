#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if fetch_sql 'SELECT 1 FROM desk WHERE EXISTS (SELECT 1 FROM desk WHERE id = 0)';

my @alters;

if (db_version ge '7.3') {
    # Yay, we can just alter the columns!
    push @alters,
      q{ALTER TABLE story ALTER COLUMN desk__id SET NOT NULL},
      q{ALTER TABLE story ALTER COLUMN workflow__id SET NOT NULL},
      q{ALTER TABLE media ALTER COLUMN desk__id SET NOT NULL},
      q{ALTER TABLE media ALTER COLUMN workflow__id SET NOT NULL},
      q{ALTER TABLE formatting ALTER COLUMN desk__id SET NOT NULL},
      q{ALTER TABLE formatting ALTER COLUMN workflow__id SET NOT NULL},
    ;
} else {
    # We have to get a little bit trickier.
    for my $t (qw(story media formatting)) {
        for my $c(qw(desk__id workflow__id)) {
            push @alters,
              qq{LOCK TABLE $t IN ACCESS EXCLUSIVE MODE},
              qq{UPDATE pg_attribute
                 SET    attnotnull = 't'
                 WHERE  attname='$c'
                        AND attrelid = (
                            SELECT oid
                            FROM   pg_class
                            WHERE  relkind='r'
                                   AND relname='$t'
                         )}
            ;
        }
    }
}

do_sql
  # Create the new desk and workflow.
  q{INSERT INTO desk (id, name, description, asset_grp, publish, active)
    VALUES (0, 'Shelved', 'Hidden desk for shelved assets', 0, 0, 0)},

  q{INSERT INTO workflow (id, name, description, asset_grp_id, all_desk_grp_id,
                          req_desk_grp_id, head_desk_id, type, active, site__id)
    VALUES (0, 'Shelved', 'Hidden workflow for shelved assets', 0, 41,
                          42, 0, 2, 0, 100)},

  # Update the foreign keys in the story, media, and formatting tables.
  q{UPDATE story SET desk__id = 0 WHERE desk__id is NULL},
  q{UPDATE story SET workflow__id = 0 WHERE workflow__id is NULL},
  q{UPDATE media SET desk__id = 0 WHERE desk__id is NULL},
  q{UPDATE media SET workflow__id = 0 WHERE workflow__id is NULL},
  q{UPDATE formatting SET desk__id = 0 WHERE desk__id is NULL},
  q{UPDATE formatting SET workflow__id = 0 WHERE workflow__id is NULL},

  # Recreate the desk foreign key indexes.
  q{DROP INDEX fdx_story__desk__id},
  q{CREATE INDEX fdx_story__desk__id ON story(desk__id)},
  q{DROP INDEX fdx_media__desk__id},
  q{CREATE INDEX fdx_media__desk__id ON media(desk__id)},
  q{DROP INDEX fdx_formatting__desk__id},
  q{CREATE INDEX fdx_formatting__desk__id ON formatting(desk__id)},

  # Recreate the workflow foreign key indexes.
  q{DROP INDEX fdx_story__workflow__id},
  q{CREATE INDEX fdx_story__workflow__id ON story(workflow__id)},
  q{DROP INDEX fdx_media__workflow__id},
  q{CREATE INDEX fdx_media__workflow__id ON media(workflow__id)},
  q{DROP INDEX fdx_formatting__workflow__id},
  q{CREATE INDEX fdx_formatting__workflow__id ON formatting(workflow__id)},
  @alters,
  ;



__END__
