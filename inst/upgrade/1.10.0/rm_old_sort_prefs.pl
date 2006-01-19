#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

do_sql
    q{DELETE from pref_opt WHERE value IN ('id', 'category_name')},
    q{UPDATE pref_opt SET description = 'Cover Date/Deploy Date'
      WHERE value = 'cover_date'},
    q{UPDATE pref_opt SET description = 'Document Type/Output Channel'
      WHERE value = 'element'},
;

