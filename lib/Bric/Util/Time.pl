#!/usr/bin/perl -w
use strict;

use Bric::Util::Time qw(:all);

$ENV{TZ} = 'PST8PDT';
my $utc_date = strfdate(undef, undef, 1);
print "UTC Date  : $utc_date\n";
my $local_date = local_date(undef, undef, 1);
print "Local Date: $local_date\n";
my $db_date = db_date(undef, 1);
print "DB Date   : $db_date\n";
$db_date = db_date($local_date);
print "DB Date   : $db_date\n";
$local_date = local_date($db_date);
print "Local Date: $local_date\n";
