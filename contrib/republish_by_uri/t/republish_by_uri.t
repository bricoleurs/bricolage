#!/usr/bin/perl -w

use strict;
use File::Spec::Functions 'catfile';
print "1..1\n";
my $script = catfile qw(bin republish_by_uri);

# Prevent "syntax OK" output.
close STDERR;

my $ret = system $^X, '-cw', $script;
print +($ret ? 'not ' : ''), "ok 1\n"
