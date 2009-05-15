#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

do_sql
    q{ALTER TABLE category ADD COLUMN new_name varchar(128)},
    q{UPDATE category SET new_name = CAST(name AS varchar(128))},
    q{ALTER TABLE category DROP COLUMN name},
    q{ALTER TABLE category RENAME new_name TO name},
    q{CREATE INDEX idx_category__name ON category(LOWER(name))}
;
