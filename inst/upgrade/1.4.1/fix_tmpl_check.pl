#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

# First, drop the old constraint. If this fails, the constraint has already
# been replaced.
exit unless test_sql
  q{ALTER TABLE formatting
    DROP  CONSTRAINT ck_media__deploy_status};

# Now create the new constraint with the correct name.
do_sql
  q{ALTER TABLE formatting
    ADD   CONSTRAINT ck_formatting__deploy_status
          CHECK (deploy_status IN (0,1))},
  ;
