#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

do_sql <<'    END_SQL';
    DELETE FROM event_type_attr
    WHERE event_type__id in (
        SELECT id
        FROM event_type
        WHERE key_name like 'element_data%'
    )
    END_SQL

