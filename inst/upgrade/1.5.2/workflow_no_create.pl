#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Util::DBI qw(:all);

exit unless fetch_sql
  q{SELECT value
    FROM   grp_priv
    WHERE  value = 3
           AND id in ( SELECT grp_priv__id
                       FROM   grp_priv__grp_member gm, workflow w
                       WHERE  w.asset_grp_id = gm.grp__id )};

my $sel = prepare("SELECT w.asset_grp_id, d.asset_grp
                   FROM   workflow w, desk d
                   WHERE  d.id = w.head_desk_id");

my $wchk = prepare("SELECT gp.value
                    FROM   grp_priv gp, grp_priv__grp_member gm
                    WHERE  gp.id = gm.grp_priv__id
                           AND gp.value = 3
                           AND gm.grp__id = ?");

my $dchk = prepare("SELECT gp.value
                    FROM   grp_priv gp, grp_priv__grp_member gm
                    WHERE  gp.id = gm.grp_priv__id
                           AND gp.value = 2
                           AND gm.grp__id = ?");

my $upd = prepare("UPDATE grp_priv
                   SET    value = ?
                   WHERE  id in ( SELECT grp_priv__id
                                  FROM   grp_priv__grp_member gm
                                  WHERE  gm.grp__id = ? )");

execute($sel);
my ($wf_agid, $d_agid);
bind_columns($sel, \$wf_agid, \$d_agid);
while (fetch($sel)) {
    execute($wchk, $wf_agid);
    execute($dchk, $d_agid);
    if (fetch($wchk) and fetch($dchk)) {
        execute($upd, 2, $wf_agid);
        execute($upd, 3, $d_agid);
    }
    finish($wchk);
    finish($dchk);
}

__END__
do_sql
  q{UPDATE grp_priv
    SET    value = 2
    WHERE  value = 3
           AND id in ( SELECT grp_priv__id
                       FROM   grp_priv__grp_member gm, workflow w
                       WHERE  w.asset_grp_id = gm.grp__id)}
  ;
