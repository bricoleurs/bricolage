#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

# Check to see if we've run this before.
exit if test_sql('SELECT * from output_channel_include');

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
