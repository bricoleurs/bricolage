package Bric::Dist::ActionType::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Dist::ActionType');
}

##############################################################################
# Test class methods.
##############################################################################
# Test my_meths().
sub test_my_meths : Test(11) {
    ok( my $meths = Bric::Dist::ActionType->my_meths, "Get my_meths" );
    isa_ok($meths, 'HASH', "my_meths is a hash" );
    is( $meths->{name}{type}, 'short', "Check name type" );
    ok( $meths = Bric::Dist::ActionType->my_meths(1), "Get my_meths array ref" );
    isa_ok( $meths, 'ARRAY', "my_meths(1) is an array" );
    (is $meths->[0]->{name}, 'name', "Check first meth name" );

    # Try the identifier methods.
    ok( my $at = Bric::Dist::ActionType->new({ name => 'NewFoo' }),
        "Create action type" );
    ok( my @meths = $at->my_meths(0, 1), "Get ident meths" );
    is( scalar @meths, 1, "Check for 1 meth" );
    is( $meths[0]->{name}, 'name', "Check for 'name' meth" );
    is( $meths[0]->{get_meth}->($at), 'NewFoo', "Check name 'NewFoo'" );
}
1;
__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl -w
use Test;
use Bric::Dist::ActionType;

BEGIN { plan tests => 10 }

eval {

    if (@ARGV) {
    # Do verbose testing here.
    print "Getting ActionType #4.\n";
    my $at = Bric::Dist::ActionType->lookup({ id => 4 });
    print "ID:         ", $at->get_id, "\n";
    print "Name:       ", $at->get_name, "\n";
    print "Desc:       ", $at->get_description, "\n";
    print "Active:     ", $at->is_active ? 'Yes' : 'No', "\n";
    print "MEDIA Types:";
    if (my @medias = $at->get_media_types) {
        print "\n  $_" for @medias;
    } else {
        print " All.";
    }
    print "\n\n";

    print "Getting ActionType 'Put'.\n";
    $at = Bric::Dist::ActionType->lookup({ name => 'Put' });
    print "ID:         ", $at->get_id, "\n";
    print "Name:       ", $at->get_name, "\n";
    print "Desc:       ", $at->get_description, "\n";
    print "Active:     ", $at->is_active ? 'Yes' : 'No', "\n";
    print "MEDIA Types:";
    if (my @medias = $at->get_media_types) {
        print "\n  $_" for @medias;
    } else {
        print " All.";
    }
    print "\n\n";

    exit;
    }

    # Do Test::Harness testing here.


    exit;
};

if (my $err = $@) {
    print "Error: ", ref $err ? $err->{msg} . ":\n\n" . $err->{payload}
      . "\n" : "$err\n";
}

