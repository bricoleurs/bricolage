#!/usr/bin/perl -w

use strict;
use File::Spec::Functions 'catfile';
print "1..1\n";
my $script = catfile qw(bin bric_template_dump);

# Prevent "syntax OK" output.
close STDERR;

my $ret = system $^X, '-cw', $script, qw( --username foo --password bar oc);
print +($ret ? 'not ' : ''), "ok 1\n"
