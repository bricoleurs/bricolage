#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

do_sql "UPDATE media_instance
        SET    media_type__id = 0
        WHERE  media_type__id IS NULL
";
