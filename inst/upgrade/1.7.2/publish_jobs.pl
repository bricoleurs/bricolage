#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# Exit if we've already done the work.
exit if fetch_sql 'SELECT 1 FROM class WHERE id = 80';

do_sql
    # add the new columns to the job table
    q{ALTER TABLE job ADD story__id NUMERIC(10,0)},
    q{ALTER TABLE job ADD media__id NUMERIC(10,0)},
    q{ALTER TABLE job ADD class__id NUMERIC(10,0)},
    q{ALTER TABLE job ADD executing NUMERIC(1,0)},
    q{ALTER TABLE job ADD failed NUMERIC(1,0)},
    q{ALTER TABLE job ADD error_message VARCHAR(2000)},
    q{ALTER TABLE job ADD priority NUMERIC(1,0)},

    # pending -> executing
    q{UPDATE job SET executing = 0},

    # failed = 0
    q{UPDATE job SET failed = 0},

    # priority defaults to 3
    q{UPDATE job SET priority = 3},

    # update the existing class rows
    q{UPDATE  class 
      SET     pkg_name = 'Bric::Util::Job'
      WHERE   pkg_name = 'Bric::Dist::Job'},

    # insert the new class rows
    q{INSERT INTO class (id, key_name, pkg_name, disp_name, 
                         plural_name, description, distributor)
      VALUES (79, 'dist_job', 'Bric::Util::Job::Dist', 'Distribution Job', 
              'Distribution Jobs', 'Distribution job objects.', 0)},

    q{INSERT INTO class (id, key_name, pkg_name, disp_name, 
                         plural_name, description, distributor)
      VALUES (80, 'pub_job', 'Bric::Util::Job::Pub', 'Publication Job', 
              'Publication Jobs', 'Publication job objects.', 0)},

    # existing jobs are all dist jobs, mark them as such
    q{UPDATE job SET class__id = 79},

    # add the contraints
    q{ALTER TABLE job ADD CONSTRAINT ck_job__priority CHECK (priority BETWEEN 1 AND 5)},
    q{ALTER TABLE job ADD CONSTRAINT ck_job__failed CHECK (failed IN (1,0))},
    q{ALTER TABLE job ADD CONSTRAINT ck_job__executing CHECK (failed IN (1,0))},

    # create a couple of indexes
    q{CREATE INDEX idx_job__pending ON job(pending)},
    q{CREATE INDEX idx_job__class__id ON job(class__id)},
  ;

__END__

