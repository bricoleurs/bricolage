#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);
use Bric::Util::Grp::User;
use Bric::Util::Priv;

BEGIN { push @INC, catdir $FindBin::Bin, updir, updir, updir, 'lib' }

use Bric::Biz::Site;

# If there is a site with PUBLIH in its name, we've already been upgraded.
exit if fetch_sql
  q{SELECT 1
    FROM   grp
    WHERE  description = '__Site 100 Users__'
           AND name like '%PUBLISH Users'};

# We need to create secret, hidden RECALL and PUBLISH user groups for every
# site. I've basically just copied code from Bric::Biz::Site to do the job in
# the same way.

my $privs = { 3 => 'RECALL',
              5 => 'PUBLISH'
            };

for my $site (Bric::Biz::Site->list) {
    my $grp = $site->get_asset_grp;
    my $name = $site->get_name;
    my $id = $site->get_id;

    while (my ($priv, $field) = each %$privs) {
        my $g = Bric::Util::Grp::User->new({
            name        => "$name $field Users",
            description => "__Site $id Users__",
            secret      => 1,
            permanent   => 1
        });
        $g->save;
        Bric::Util::Priv->new({ obj_grp => $grp,
                                usr_grp => $g,
                                value   => $priv })->save;
    }
}
