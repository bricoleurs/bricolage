#!/usr/bin/perl -w

# $Id: bric_template_dump.t,v 1.1 2004-03-23 22:23:11 wheeler Exp $

use strict;

print "1..1\n";
my $ret = system $^X, qw(-cw bric_template_dump --username foo --password bar oc);
print +($ret ? 'not ' : ''), "ok 1\n"
