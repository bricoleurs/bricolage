#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

do_sql q{UPDATE event_type SET class__id = 46 WHERE key_name = 'media_expire'};

__END__
