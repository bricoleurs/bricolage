#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);


# add the new fields and indexes,
do_sql(q{ ALTER TABLE category ADD COLUMN uri VARCHAR(256) },
       q{ ALTER TABLE category ADD COLUMN parent_id NUMERIC(10,0) },
       q{ CREATE UNIQUE INDEX idx_category__uri ON category(uri) },
       q{ CREATE UNIQUE INDEX idx_category__lower_uri ON category(LOWER(uri)) },
       q{ CREATE INDEX idx_category__parent_id ON category(parent_id) },
       q{ CREATE INDEX fkx_subcat_grp__category ON category(category_grp_id) },
      )
  unless (fetch_sql(q{ SELECT uri FROM category }));

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
  my ($dirname, $grp_id);

  $uri =~ s!/$!!;

  execute($get_dir, $id);
  bind_columns($get_dir, \$dirname);
  while (fetch($get_dir)) {
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
