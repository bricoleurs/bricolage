#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

# check if we're already upgraded.
exit if (fetch_sql(q{ SELECT uri FROM category }));

# add the new fields and indexes,
do_sql(q{ ALTER TABLE category ADD COLUMN uri VARCHAR(256) },
       q{ ALTER TABLE category ADD COLUMN parent_id NUMERIC(10,0) },
       q{ CREATE UNIQUE INDEX udx_category__uri ON category(uri) },
       q{ CREATE INDEX idx_category__lower_uri ON category(LOWER(uri)) },
       q{ CREATE INDEX idx_category__parent_id ON category(parent_id) },
      );


update_kids(0, 0, "", 0);

do_sql(q{ ALTER TABLE category
            ADD CONSTRAINT check_uri_null CHECK (uri is NOT NULL)
       },
       q{ ALTER TABLE category
            ADD CONSTRAINT check_pid_null CHECK (parent_id is NOT NULL)
       },
);

sub update_kids {
  my ($id, $sp, $uri, $pid) = @_;
  my $get_grp = prepare("SELECT category_grp_id FROM category WHERE id=?");
  my $get_dir = prepare("SELECT directory FROM category WHERE id=?");
  my $get_active = prepare("SELECT active FROM category WHERE id=?");
  my ($dirname, $grp_id, $active);

  # skip inactive categories since they may have duplicate URIs
  execute($get_active, $id);
  bind_columns($get_active, \$active);
  fetch($get_active);
  return unless $active;

  $uri =~ s!/$!!;

  execute($get_dir, $id);
  bind_columns($get_dir, \$dirname);
  while (fetch($get_dir)) {
    # remove slashes in the dirname.  These are no longer allowed and
    # mess up the generated URI.
    $dirname =~ s/\///g;
    do_sql("UPDATE category SET uri='$uri/$dirname' WHERE id=$id");
    do_sql("UPDATE category SET parent_id=$pid WHERE id=$id");
  }

  execute($get_grp, $id);
  bind_columns($get_grp, \$grp_id);
  while (fetch($get_grp)) {
    my $get_kids = prepare("SELECT id FROM grp WHERE parent_id=?");
    my $kid_grp_id;

    execute($get_kids, $grp_id);
    bind_columns($get_kids, \$kid_grp_id);
    while (fetch($get_kids)) {
      my $get_id = prepare("SELECT id FROM category WHERE category_grp_id=?");
      my $kid_id;

      execute($get_id, $kid_grp_id);
      bind_columns($get_id, \$kid_id);
      while (fetch($get_id)) {
        update_kids($kid_id, $sp+1, "$uri/$dirname", $id);
      }
    }
  }
}
