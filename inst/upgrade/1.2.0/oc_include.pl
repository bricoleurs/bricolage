#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# Check to see if we've run this before.
exit if test_table 'output_channel_include';

my @sql = (
   'CREATE SEQUENCE seq_output_channel_include START 1024',

   "CREATE TABLE output_channel_include (
    id          NUMERIC(10,0)  NOT NULL
                               DEFAULT NEXTVAL('seq_output_channel_include'),
    output_channel__id   NUMERIC(10,0)  NOT NULL,
    include_oc_id              NUMERIC(10,0)  NOT NULL
                               CONSTRAINT ck_oc_include__include_oc_id
                                 CHECK (include_oc_id <> output_channel__id),
    CONSTRAINT pk_output_channel_include__id PRIMARY KEY (id)",
);

do_sql(@sql);
