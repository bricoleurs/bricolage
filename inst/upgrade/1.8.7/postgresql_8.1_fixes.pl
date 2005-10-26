#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

do_sql q{
    ALTER TABLE attr_grp_meta
    ALTER COLUMN id SET DEFAULT NEXTVAL('seq_attr_grp_meta')
};

do_sql q{
    ALTER TABLE story_container_tile
    ALTER COLUMN id SET DEFAULT  NEXTVAL('seq_story_container_tile')
} if test_table 'story_container_tile';


__END__
