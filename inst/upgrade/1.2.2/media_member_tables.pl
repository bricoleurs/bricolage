#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# Check to see if we've run this before.
exit if test_table 'audio_member';

do_sql(

    qq{
    CREATE TABLE audio_member (
        id          NUMERIC(10,0)  NOT NULL
                                   DEFAULT NEXTVAL('seq_audio_member'),
        object_id   NUMERIC(10,0)  NOT NULL,
        member__id  NUMERIC(10,0)  NOT NULL,
        CONSTRAINT pk_audio_member__id PRIMARY KEY (id)
    )},

    qq{
    CREATE TABLE video_member (
        id          NUMERIC(10,0)  NOT NULL
                                   DEFAULT NEXTVAL('seq_video_member'),
        object_id   NUMERIC(10,0)  NOT NULL,
        member__id  NUMERIC(10,0)  NOT NULL,
        CONSTRAINT pk_video_member__id PRIMARY KEY (id)
    )},
);

__END__
