#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# Just exit if the function already exists.
exit if test_function 'append_id';

# Create the function and the aggregate.

do_sql
  q{CREATE   FUNCTION append_id(TEXT, NUMERIC(10,0))
    RETURNS  TEXT AS 'SELECT $1 || '' '' || CAST($2 AS TEXT)'
    LANGUAGE 'sql'
    WITH     (ISCACHABLE, ISSTRICT)},

  q{CREATE AGGREGATE id_list (
        SFUNC    = append_id,
        BASETYPE = NUMERIC(10, 0),
        STYPE    = TEXT,
        INITCOND = ''
    )},
  ;
