package Bric::Util::Time::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

# Register this class for testing.
BEGIN { __PACKAGE__->test_class }

##############################################################################
# Test class loading.
##############################################################################
sub test_load : Test(1) {
    use_ok('Bric::Util::Time');
}


__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

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
