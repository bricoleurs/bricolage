#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

unless (test_foreign_key 'job', 'fk_job__usr') {
    do_sql "
        ALTER TABLE job ADD CONSTRAINT fk_job__usr
        FOREIGN KEY (usr__id)
        REFERENCES usr(id) ON DELETE CASCADE";
}

unless (test_foreign_key 'job', 'fk_job__class') {
    do_sql "
      ALTER TABLE job ADD CONSTRAINT fk_job__class
      FOREIGN KEY (class__id)
      REFERENCES class(id) ON DELETE CASCADE";
}

unless (test_foreign_key 'job', 'fk_job__story') {
    do_sql "
      ALTER TABLE job ADD CONSTRAINT fk_job__story
      FOREIGN KEY (story__id)
      REFERENCES story(id) ON DELETE CASCADE";
}

unless (test_foreign_key 'job', 'fk_job__media') {
    do_sql "
      ALTER TABLE job ADD CONSTRAINT fk_job__media
      FOREIGN KEY (media__id)
      REFERENCES media(id) ON DELETE CASCADE";
}

unless (test_foreign_key 'job__resource', 'fk_job__job__resource') {
    do_sql "
      ALTER TABLE job__resource ADD CONSTRAINT fk_job__job__resource
      FOREIGN KEY (job__id)
      REFERENCES job(id) ON DELETE CASCADE";
}

unless (test_foreign_key 'job__resource', 'fk_resource__job__resource') {
    do_sql "
      ALTER TABLE job__resource ADD CONSTRAINT fk_resource__job__resource
      FOREIGN KEY (resource__id)
      REFERENCES resource(id) ON DELETE CASCADE";
}

unless (test_foreign_key 'job__server_type', 'fk_job__job__server_type') {
    do_sql "
      ALTER TABLE job__server_type ADD CONSTRAINT fk_job__job__server_type
      FOREIGN KEY (job__id)
      REFERENCES job(id) ON DELETE CASCADE";
}

unless (test_foreign_key 'job__server_type', 'fk_srvr_type__job__srvr_type') {
    do_sql "
      ALTER TABLE job__server_type ADD CONSTRAINT fk_srvr_type__job__srvr_type
      FOREIGN KEY (server_type__id)
      REFERENCES server_type(id) ON DELETE CASCADE";
}

unless (test_foreign_key 'job_member', 'fk_job__job_member') {
    do_sql "
      ALTER TABLE    job_member
      ADD CONSTRAINT fk_job__job_member FOREIGN KEY (object_id)
      REFERENCES     job(id) ON DELETE CASCADE";
}

unless (test_foreign_key 'job_member', 'fk_member__job_member') {
    do_sql "
      ALTER TABLE    job_member
      ADD CONSTRAINT fk_member__job_member FOREIGN KEY (member__id)
      REFERENCES     member(id) ON DELETE CASCADE";
}
