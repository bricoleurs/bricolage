#!/usr/bin/perl -w

# $Id: bric_template_dump.t,v 1.2 2004-03-24 19:10:21 wheeler Exp $

use strict;
use File::Spec::Functions 'catfile';
print "1..1\n";
my $script = catfile qw(bin bric_template_dump);

# Prevent "syntax OK" output.
close STDERR;

my $ret = system $^X, '-cw', $script, qw( --username foo --password bar oc);
print +($ret ? 'not ' : ''), "ok 1\n"
