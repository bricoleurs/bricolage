#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

do_sql "UPDATE class
        SET    disp_name = 'Group Group',
               plural_name = 'Group Groups'
        WHERE  key_name = 'grp_grp'
";
