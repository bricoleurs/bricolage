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

