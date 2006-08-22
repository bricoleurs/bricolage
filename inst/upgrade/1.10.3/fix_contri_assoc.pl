#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

do_sql
    q{UPDATE story__contributor SET role = 'DEFAULT' WHERE role IS NULL},
    q{UPDATE media__contributor SET role = 'DEFAULT' WHERE role IS NULL},
;
