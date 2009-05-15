package Bric::Util::Class::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Util::Class');
}

1;
__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl -w
use Test;
use Bric::Util::Class;

BEGIN { plan tests => 10 }

eval {

    if (@ARGV) {
    # Do verbose testing here.
    print "Getting a class.\n";
    my $c = Bric::Util::Class->lookup({ id => 3 });
    print "Name:      ", $c->get_disp_name, "\n";
    print "Plural:    ", $c->get_plural_name, "\n";
    print "Package:   ", $c->get_pkg_name, "\n";
    print "Key:       ", $c->get_key_name, "\n";
    print "Desc:      ", $c->get_description, "\n";
    print "Distrib:   ", $c->get_distributor ? 'Yes' : 'No',  "\n";

    exit;
    print "Cleaning up bogus records.\n";
        Bric::Util::DBI::prepare_c(qq{
            DELETE FROM class
            WHERE  id > 1023
        })->execute;
    print "Done!\n";
    }

    # Do Test::Harness testing here.


    exit;
    Bric::Util::DBI::prepare_c(qq{
        DELETE FROM class
        WHERE  id > 1023
    })->execute;
};

if (my $err = $@) {
    if (ref $err) {
    print "Error: ", $err->get_msg, ": ", $err->get_payload, "\n";
    } else {
    print "Error: $err\n";
    }
}

1;
