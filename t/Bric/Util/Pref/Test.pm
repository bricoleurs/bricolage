package Bric::Util::Pref::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Util::Pref');
}

##############################################################################
# Test class methods.
##############################################################################
# Test my_meths().
sub test_my_meths : Test(11) {
    ok( my $meths = Bric::Util::Pref->my_meths, "Get my_meths" );
    isa_ok($meths, 'HASH', "my_meths is a hash" );
    is( $meths->{name}{type}, 'short', "Check name type" );
    ok( $meths = Bric::Util::Pref->my_meths(1), "Get my_meths array ref" );
    isa_ok( $meths, 'ARRAY', "my_meths(1) is an array" );
    (is $meths->[0]->{name}, 'name', "Check first meth name" );

    # Try the identifier methods.
    ok( my $pref = Bric::Util::Pref->new({ name => 'NewFoo' }),
        "Create preference" );
    ok( my @meths = $pref->my_meths(0, 1), "Get ident meths" );
    is( scalar @meths, 1, "Check for 1 meth" );
    is( $meths[0]->{name}, 'name', "Check for 'name' meth" );
    is( $meths[0]->{get_meth}->($pref), 'NewFoo', "Check name 'NewFoo'" );
}

1;
__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl -w
use Test;
use Bric::Util::Pref;

BEGIN { plan tests => 10 }

eval {

    if (@ARGV) {
    # Do verbose testing here.
    print "Getting preference #1\n";
    my $pref = Bric::Util::Pref->lookup({ id => 1 });
    print "Name:    ", $pref->get_name || '', "\n";
    print "Desc:    ", $pref->get_description || '', "\n";
    print "Default: ", $pref->get_default || '', "\n";
    print "Value:   ", $pref->get_value || '', "\n";
    print "ValName: ", $pref->get_val_name, "\n\n";

    print "Changing its value.\n";
    $pref->set_value('Africa/Accra');
    print "ValName: ", $pref->get_val_name, "\n\n";
    $pref->save;

    print "Reloading the pref from the database.\n";
    $pref = Bric::Util::Pref->lookup({ id => 1 });
    print "Name:    ", $pref->get_name || '', "\n";
    print "Desc:    ", $pref->get_description || '', "\n";
    print "Default: ", $pref->get_default || '', "\n";
    print "Value:   ", $pref->get_value || '', "\n";
    print "ValName: ", $pref->get_val_name, "\n\n";

    print "Okay, changing its value back.\n";
    $pref->set_value('UTC');
    $pref->save;

    print "\nList of options:\n";
    foreach my $o ($pref->get_opts) {
        print "  $o\n";
    }

    print "Hashref of options:\n";
    {
        my $opts = $pref->get_opts_href;
        while (my ($k, $v) = each %$opts) {
        print "  $k => $v\n";
        }
    }

    print "\nGetting value for Time Zone.\n";
    print Bric::Util::Pref->lookup_val('Time Zone') || '', "\n";
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

