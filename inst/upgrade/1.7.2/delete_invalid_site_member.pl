#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw(catdir updir);
use FindBin;
use lib catdir $FindBin::Bin, updir, 'lib';
use bric_upgrade qw(:all);

# This was just wrong. It had added a site to an asset group, which just made
# no sense and tended to screw up permissions.

do_sql q{DELETE FROM site_member WHERE id = 2},
       q{DELETE FROM member WHERE id = 60};

__END__
