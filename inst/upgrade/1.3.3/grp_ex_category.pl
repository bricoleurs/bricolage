#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);
use Bric::Util::Grp::Asset;

exit if fetch_sql(q{ SELECT name FROM category WHERE id=0 });

# add the new fields and indexes,
do_sql(q{ ALTER TABLE category ADD COLUMN name VARCHAR(64) },
       q{ ALTER TABLE category ADD COLUMN description VARCHAR(256) },
       q{ CREATE INDEX idx_category__name ON category(LOWER(name)) },
      );


update_all();

#do_sql(q{ ALTER TABLE category
#          RENAME category_grp_id TO __category_grp_id__
#      });

sub update_all {
  my $get_grp_id = prepare("SELECT category_grp_id FROM category");
  my $get_name_desc = prepare("SELECT name, description FROM grp WHERE id=?");
  my $set_name_desc = prepare("UPDATE category SET name=?, description=? WHERE category_grp_id=?");

  my $grp_id;
  execute($get_grp_id);
  bind_columns($get_grp_id, \$grp_id);

  while (fetch($get_grp_id)) {
    my ($name, $desc);
    execute($get_name_desc, $grp_id);
    bind_columns($get_name_desc, \$name, \$desc);
    while (fetch($get_name_desc)) {
      execute($set_name_desc, $name, $desc, $grp_id);
    }
  }
}
