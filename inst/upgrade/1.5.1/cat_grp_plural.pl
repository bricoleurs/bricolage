#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

do_sql "UPDATE class SET plural_name = 'Category Groups' WHERE id = 47";
