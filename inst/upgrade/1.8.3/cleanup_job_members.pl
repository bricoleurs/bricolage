#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# This is to address the fact that the delete_old_jobs.pl script in the 1.8.2
# release could leave orphaned records in the member table.
do_sql "
   DELETE FROM member
   WHERE class__id IN (54, 79, 80)
         AND id IN (
             SELECT member__id
             FROM  job_member j LEFT JOIN member m ON (j.member__id = m.id)
             WHERE m.id IS NULL
       )
";
