#!/usr/bin/perl -w

# $Id: bric_media_dump.t 5554 2004-05-25 01:17:44Z theory $

use strict;
use File::Spec::Functions 'catfile';
print "1..1\n";
my $script = catfile qw(bin republish_by_uri);

# Prevent "syntax OK" output.
close STDERR;

my $ret = system $^X, '-cw', $script;
print +($ret ? 'not ' : ''), "ok 1\n"
