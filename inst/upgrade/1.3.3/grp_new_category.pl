#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);
use Bric::Util::Grp::Asset;

exit unless fetch_sql(q{ SELECT 1 FROM class WHERE id = 23 });

do_sql( q{ DROP INDEX fkx_subcat_grp__category });

move_privs();

do_sql(q{ UPDATE category set category_grp_id = NULL },
       q{ DELETE FROM class WHERE id = 23 },
       q{ ALTER TABLE    category
          ADD CONSTRAINT ck_category__asset_grp_id
          CHECK          (asset_grp_id IS NOT NULL)
 });

sub move_privs {
    # This subroutine is going to change the group that manages permissions.
    # For some insane reason, I chose to use the category_grp_id for setting
    # permissions on assets in a category. That never made any sense, and now
    # that we're getting rid of teh category_grp_id, it's time to switch to
    # asset_grp_id.

    # This query will get the two IDs we're interested in.
    my $sel = prepare(qq{
        SELECT id, name, category_grp_id
        FROM   category
    });

    # This statement will replace the category_grp_id with the asset_grp_id in
    # relevant permissions.
    my $upd = prepare(qq{
        UPDATE grp_priv__grp_member
        SET    grp__id = ?
        WHERE  grp__id = ?
    });

    my $cat_upd = prepare(qq{
        UPDATE category
        SET    asset_grp_id = ?
        WHERE  id = ?
    });

    my ($id, $name, $cg_id);
    execute($sel);
    bind_columns($sel, \$id, \$name, \$cg_id);
    while (fetch($sel)) {
        # Create a new asset group.
        my $ag_obj = Bric::Util::Grp::Asset->new
          ({ name => 'Category Assets',
             description => $name });
        $ag_obj->save;
        my $ag_id = $ag_obj->get_id;
        # Save the new id to the category table.
        execute($cat_upd, $ag_id, $id);
        # Swap group IDs in the permissions table.
        execute($upd, $ag_id, $cg_id);
    }
}
