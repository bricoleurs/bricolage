#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);
use Bric::Biz::Category;
use Bric::Util::Grp::Asset;

# Look up the root category.
my $cat = Bric::Biz::Category->lookup({ id => 0 });

# Construct its asset group.
my $ag = Bric::Util::Grp::Asset->lookup({ id => $cat->get_asset_grp_id });

# Just exit if its description is the same as the Root Category's URI.
exit if $ag->get_description eq $cat->get_uri;

# So update its group description.
$ag->set_description($cat->get_uri);
$ag->save;

# Now update all if its children, forcing all of their children to be updated,
# cascading all the way down the directory hierarchy.
foreach my $subcat (Bric::Biz::Category->list({ parent_id => $cat->get_id })) {
    next if $subcat->get_id == 0;
    $subcat->set_directory($subcat->_get('directory'));
    $subcat->_update_category;
    foreach my $subsubcat ($subcat->get_children) {
        $subsubcat->set_directory($subsubcat->_get('directory'));
        $subsubcat->_update_category;
    }
}
