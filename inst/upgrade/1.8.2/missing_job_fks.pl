#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);


unless (test_constraint 'job', 'fk_job__usr') {
    print STDERR "Creating fk_job__usr\n";
    do_sql "
        ALTER TABLE job ADD CONSTRAINT fk_job__usr
        FOREIGN KEY (usr__id)
        REFERENCES usr(id) ON DELETE CASCADE";
}

unless (test_constraint 'job__resource', 'fk_job__job__resource') {
    do_sql "
      ALTER TABLE job__resource ADD CONSTRAINT fk_job__job__resource
      FOREIGN KEY (job__id)
      REFERENCES job(id) ON DELETE CASCADE";
}

unless (test_constraint 'job__resource', 'fk_resource__job__resource') {
    do_sql "
      ALTER TABLE job__resource ADD CONSTRAINT fk_resource__job__resource
      FOREIGN KEY (resource__id)
      REFERENCES resource(id) ON DELETE CASCADE";
}

unless (test_constraint 'job__server_type', 'fk_job__job__server_type') {
    do_sql "
      ALTER TABLE job__server_type ADD CONSTRAINT fk_job__job__server_type
      FOREIGN KEY (job__id)
      REFERENCES job(id) ON DELETE CASCADE";
}

unless (test_constraint 'job__server_type', 'fk_srvr_type__job__srvr_type') {
    do_sql "
      ALTER TABLE job__server_type ADD CONSTRAINT fk_srvr_type__job__srvr_type
      FOREIGN KEY (server_type__id)
      REFERENCES server_type(id) ON DELETE CASCADE";
}

unless (test_constraint 'job_member', 'fk_job__job_member') {
    do_sql "
      ALTER TABLE    job_member
      ADD CONSTRAINT fk_job__job_member FOREIGN KEY (object_id)
      REFERENCES     job(id) ON DELETE CASCADE";
}

unless (test_constraint 'job_member', 'fk_member__job_member') {
    do_sql "
      ALTER TABLE    job_member
      ADD CONSTRAINT fk_member__job_member FOREIGN KEY (member__id)
      REFERENCES     member(id) ON DELETE CASCADE";
}



