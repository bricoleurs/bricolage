package Bric::Util::Fault::Test;
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
    use_ok('Bric::Util::Fault');
}


__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl -w

package Bric::Util::Fault::FaultTest;

use strict;
use Test::More tests => 66;

my @classes;
BEGIN {
    @classes = ('Bric::Util::Fault',
                'Bric::Util::Fault::Exception',
                'Bric::Util::Fault::Exception::DA'
               );
    use_ok $_ for @classes;
}

my $msg = 'Fault!';
my $payload = 'Cannot operate heavy machinery under the influence of alcohol';

foreach my $ec (@classes) {
    eval { die $ec->new({ msg => $msg, payload => $payload }) };
    ok my $err = $@, "Got $ec exception";
    isa_ok $err, $ec, "Yes, it isa $ec";
    isa_ok $err, $classes[0], "Yes, it isa $classes[0]";
    ok $err->get_timestamp <= time, "$ec: Check time";
    is $err->get_msg, $msg, "$ec: Check message";
    is $err->get_payload, $payload, "$ec: Check payload";
    is $err->get_pkg, __PACKAGE__, "$ec: Check package";
    is $err->get_filename, 'Fault.pl', "$ec: Check filename";
    is $err->get_line, 21, "$ec: Check line";
    is_deeply $err->get_env, \%ENV, "$ec: Check environment";
    is $err->error_info, __PACKAGE__ . " -- Fault.pl -- 21\n$msg\n\n$payload\n",
      "$ec: Check error_info";
    is "$err", $err->error_info, "$ec: Check stringifiation";
    ok my $stack = $err->get_stack, "$ec: Get stack";
    ok UNIVERSAL::isa($stack, 'ARRAY'), "$ec: Stack isa array";
    is $#$stack, 1, "$ec: Count stack";
    is $stack->[0][1], 'Fault.pl', "$ec: Check 0/1";
    is $stack->[0][2], 21, "$ec: Check 0/3";
    is $stack->[0][3], 'Bric::Util::Fault::new', "$ec: Check 0/2";
    is $stack->[1][1], 'Fault.pl', "$ec: Check 1/1";
    is $stack->[1][2], 21, "$ec: Check 1/3";
    is $stack->[1][3], '(eval)', "$ec: Check 1/2";
}
