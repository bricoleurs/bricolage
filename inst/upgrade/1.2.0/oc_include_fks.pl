#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# Check to see if we've run this before.
exit if test_index 'fkx_output_channel__oc_include';

my @sql = (
   'CREATE INDEX fkx_output_channel__oc_include ON output_channel_include(output_channel__id)',
   'CREATE INDEX fkx_oc__oc_include_inc ON output_channel_include(include_oc_id)',
   'CREATE UNIQUE INDEX udx_output_channel_include ON output_channel_include(output_channel__id, include_oc_id)',

   "ALTER TABLE    output_channel_include
    ADD CONSTRAINT fk_output_channel__oc_include FOREIGN KEY (output_channel__id)
    REFERENCES     output_channel(id) ON DELETE CASCADE",

   "ALTER TABLE    output_channel_include
    ADD CONSTRAINT fk_oc__oc_include_inc FOREIGN KEY (include_oc_id)
    REFERENCES     output_channel(id) ON DELETE CASCADE",
);

do_sql(@sql);
