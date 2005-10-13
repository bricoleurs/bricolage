#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit unless y_n
q{
    This upgrade makes changes to the distribution jobs table in the
    database that can take a long time and be very resource intensive
    if there have been a lot of jobs. However, the time and CPU
    resources can be dramatically reduced by deleting all existing
    completed jobs from the database. These jobs will no longer
    exist in Bricolage, so there will no longer be a record of them.
    This data is not currently accessible in the Bricolage user
    interface, and, if deleted, will not affect current pending or
    future distribution jobs.

    Would you like to delete all existing completed distribution jobs?},
  'y';


do_sql
  "DELETE FROM job
   WHERE  executing = 0
          AND (
            comp_time IS NOT NULL
            OR failed = 1
          )",

  "DELETE FROM member
   WHERE class__id IN (54, 79, 80)
         AND id IN (
             SELECT member__id
             FROM  job_member j LEFT JOIN member m ON (j.member__id = m.id)
             WHERE m.id IS NULL
       )",
  ;
