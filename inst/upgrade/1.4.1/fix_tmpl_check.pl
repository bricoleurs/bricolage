#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

exit if test_constraint 'formatting', 'ck_formatting__deploy_status';

# Drop the old constraint and create the new one with the correct name.
do_sql
  q{ALTER TABLE formatting
    DROP  CONSTRAINT ck_media__deploy_status},

  q{ALTER TABLE formatting
    ADD   CONSTRAINT ck_formatting__deploy_status
          CHECK (deploy_status IN (0,1))},
  ;
