package Bric::Util::Grp::Parts::Member::Contrib::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Util::Grp::Parts::Member::Contrib');
}

1;
__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl -w
use Test;
use Bric::Util::Grp::Parts::Member::Contrib;

BEGIN { plan tests => 10 }

eval {

    if (@ARGV) {
    # Do verbose testing here.
    print "Getting a list of contributors.\n";
    foreach my $c (Bric::Util::Grp::Parts::Member::Contrib->list) {
        print "ID:     ", $c->get_id || '', "\n";
        print "PID:    ", $c->get_obj_id || '', "\n";
        print "GID:    ", $c->get_grp_id || '', "\n\n";
    }

    print "Testing my_meths().\n";
    foreach my $meth (Bric::Util::Grp::Parts::Member::Contrib->my_meths(1)) {
        print "$meth->{disp}\n";
    }
    exit;
    }

    # Do Test::Harness testing here.


    exit;
};

if (my $err = $@) {
    if (ref $err) {
    print "Error: ", $err->get_msg, ": ", $err->get_payload, "\n";
    } else {
    print "Error: $err\n";
    }
}

