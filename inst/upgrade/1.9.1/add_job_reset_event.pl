#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

exit if fetch_sql q{SELECT 1 FROM event_type WHERE key_name = 'job_reset'};

do_sql q{
    INSERT INTO event_type (id, key_name, name, description, class__id, active)
    VALUES (NEXTVAL('seq_event_type'), 'job_reset', 'Job Reset', 'Job was reset.', '54', '1');
};
