#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# Check to see if we've run this before.
exit if test_index 'fkx_audio__audio_member';

do_sql(
    'CREATE INDEX fkx_audio__audio_member ON audio_member(object_id)',
    'CREATE INDEX fkx_member__audio_member ON audio_member(member__id)',
    'CREATE SEQUENCE seq_audio_member START  1024',

    'CREATE INDEX fkx_video__video_member ON video_member(object_id)',
    'CREATE INDEX fkx_member__video_member ON video_member(member__id)',
    'CREATE SEQUENCE seq_video_member START  1024'
);

__END__
