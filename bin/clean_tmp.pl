#!/usr/bin/perl -w
use strict;

=pod

=head1 NAME

clean_tmp.pl

=head1 SYNOPSIS

This script is designed to be run from cron.  To run it nightly at 2am put a
like like this in the crontab for the web server user (often "nobody"):

    0 2 * * * /usr/local/bricolage/bin/clean_tmp.pl

=head1 DESCRIPTION

clean_tmp.pl will delete files from the tmp directories used by
Bricolage which are over a 12 hours old.  This will prevent Bricolage
from filling up your hard drive with stale lockfiles and other
viscera.

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

=cut

use File::Spec;
use File::Find qw(find);

my $tmpdir = File::Spec->tmpdir();
die "Unable to find tmp dir using File::Spec::tmp_dir()!"
  unless $tmpdir;

# epoch twelve hours ago
my $cutoff = time - (12 * 60 * 60);
                        
# find and delete old files
find(sub {
       if (-f and (stat(_))[8] < $cutoff) {
         unlink($_) or die "Unable to delete $File::Find::name : $!";
       }
     }, 
     File::Spec->catdir($tmpdir, "bricolage")
    );
