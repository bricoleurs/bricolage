#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

exit if test_sql "SELECT 1 WHERE EXISTS (SELECT asset_grp_id FROM workflow)";

do_sql
  # Restore missing constraints.
  q{ALTER TABLE    workflow
    ADD CONSTRAINT fk_grp__workflow__all_desk_grp_id FOREIGN KEY (all_desk_grp_id)
    REFERENCES     grp(id) ON DELETE CASCADE},

  q{ALTER TABLE    workflow
    ADD CONSTRAINT fk_grp__workflow__req_desk_grp_id FOREIGN KEY (req_desk_grp_id)
    REFERENCES     grp(id) ON DELETE CASCADE},

  # Restore missing indexes.
  q{CREATE INDEX fkx_grp__workflow__all_desk_grp_id ON workflow(all_desk_grp_id)},
  q{CREATE INDEX fkx_grp__workflow__req_desk_grp_id ON workflow(req_desk_grp_id)},

  # Add the new asset_grp_id column.
  q{ALTER TABLE workflow ADD COLUMN asset_grp_id NUMERIC(10, 0)},

  # Create a constraint on it.
  q{ALTER TABLE    workflow
    ADD CONSTRAINT fk_grp__workflow__asset_grp_id FOREIGN KEY (asset_grp_id)
    REFERENCES     grp(id) ON DELETE CASCADE},

  # Create an index on it.
  q{CREATE INDEX fkx_grp__workflow__asset_grp_id ON workflow(asset_grp_id)},

  ;

# Create the new groups.
my $sel = prepare("SELECT id, all_desk_grp_id FROM workflow");
my $upd = prepare("UPDATE workflow SET asset_grp_id = ? WHERE id = ?");
my $upd_priv = prepare("UPDATE grp_priv__grp_member SET grp__id = ? WHERE grp__id = ?");
execute($sel);
my ($wf_id, $all_grp_id);
bind_columns($sel, \$wf_id, \$all_grp_id);
while (fetch($sel)) {
    my $gid = create_group($wf_id);
    execute($upd, $gid, $wf_id);
    execute($upd_priv, $gid, $all_grp_id);
}

# Add the NOT NULL constraint.
do_sql
  q{ALTER TABLE workflow
      ADD CONSTRAINT ck_workflow__asset_grp_id_null
      CHECK (asset_grp_id is NOT NULL)},
  ;

sub create_group {
    my $wf_id = shift;
    do_sql
      q{INSERT INTO grp (id, parent_id, class__id, name, description,
                         secret, permanent)
        VALUES (NEXTVAL('seq_grp'), NULL, 43, 'Workflow Assets',
                'Assets group for workflow permissions', 1, 0)},

       q{INSERT INTO member (id, grp__id, class__id, active)
         VALUES (NEXTVAL('seq_member'), CURRVAL('seq_grp'), 6, 1)},

       qq{INSERT INTO grp_member (id, object_id, member__id)
          VALUES (NEXTVAL('seq_grp_member'), CURRVAL('seq_grp'),
                  CURRVAL('seq_member'))},
       ;
    return last_key('grp');

}


1;
__END__
* Create new asset groups for each WF.
* Update the relevant permission records with the new group IDs.

