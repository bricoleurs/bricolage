#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);
use Bric::Config;

exit if test_column('pref', 'can_be_overridden');

do_sql
q/
ALTER TABLE pref ADD COLUMN
can_be_overridden  NUMERIC(1,0)   NULL
                                  CONSTRAINT ck_pref__can_be_overridden
                                    CHECK (can_be_overridden IN (0,1))
/;
