#!/usr/bin/perl
# Test the help button.

use strict;
use warnings;
use Test::More 'no_plan';

use lib 't/UI';
use TestMech;

my $mech = TestMech->new();

# Help button uses JavaScript, so we have to get the link directly
$mech->get('/help/en_us/workflow/profile/workspace.html');
$mech->title_is('Bricolage Help', 'get Help button');
