#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir catfile);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# Check if we're already upgraded.
exit if test_index 'idx_event__obj_id';

do_sql 'CREATE INDEX idx_event__obj_id ON event(obj_id)';
