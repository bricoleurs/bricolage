#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use bric_upgrade qw(:all);

# Check the version number.
exit unless is_later(1.2.2);

# Check to see if we've run this before.
exit if test_sql('SELECT * from audio_member');

do_sql(

    qq{
    CREATE TABLE audio_member (
        id          NUMERIC(10,0)  NOT NULL
                                   DEFAULT NEXTVAL('seq_audio_member'),
        object_id   NUMERIC(10,0)  NOT NULL,
        member__id  NUMERIC(10,0)  NOT NULL,
        CONSTRAINT pk_audio_member__id PRIMARY KEY (id)
    )},

    'CREATE INDEX fkx_audio__audio_member ON audio_member(object_id)',
    'CREATE INDEX fkx_member__audio_member ON audio_member(member__id)',
    'CREATE SEQUENCE seq_audio_member START  1024',

    qq{
    CREATE TABLE video_member (
        id          NUMERIC(10,0)  NOT NULL
                                   DEFAULT NEXTVAL('seq_video_member'),
        object_id   NUMERIC(10,0)  NOT NULL,
        member__id  NUMERIC(10,0)  NOT NULL,
        CONSTRAINT pk_video_member__id PRIMARY KEY (id)
    )},

    'CREATE INDEX fkx_video__video_member ON video_member(object_id)',
    'CREATE INDEX fkx_member__video_member ON video_member(member__id)',
    'CREATE SEQUENCE seq_video_member START  1024'
);

__END__
