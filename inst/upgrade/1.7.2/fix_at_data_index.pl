#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# Drop any existance of the old index.
do_sql q/DROP INDEX udx_atd__name__at_id/
  if test_index 'udx_atd__name__at_id';

# Drop any existance of the newer but incorrect index.
do_sql q/DROP INDEX udx_atd__key_name__at_id/
  if test_index 'udx_atd__key_name__at_id';

# Create the proper index.
do_sql
  q/CREATE UNIQUE INDEX udx_atd__key_name__at_id ON at_data(lower_text_num(key_name, element__id))/
  ;
