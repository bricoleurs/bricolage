#!/usr/bin/perl -w

use strict;
use File::Spec::Functions 'catfile';
print "1..1\n";
my $script = catfile qw(bin bric_media_dump);

# Prevent "syntax OK" output.
close STDERR;

my $ret = system $^X, '-cw', $script, qw( --username foo --password bar --media-type bing);
print +($ret ? 'not ' : ''), "ok 1\n"
