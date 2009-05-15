package Bric::Util::EventType::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Util::EventType');
}

##############################################################################
# Test class methods.
##############################################################################
# Test my_meths().
sub test_my_meths : Test(11) {
    ok( my $meths = Bric::Util::EventType->my_meths, "Get my_meths" );
    isa_ok($meths, 'HASH', "my_meths is a hash" );
    is( $meths->{name}{type}, 'short', "Check name type" );
    ok( $meths = Bric::Util::EventType->my_meths(1), "Get my_meths array ref" );
    isa_ok( $meths, 'ARRAY', "my_meths(1) is an array" );
    (is $meths->[0]->{name}, 'key_name', "Check first meth name" );

    # Try the identifier methods.
    ok( my $et = Bric::Util::EventType->new({ key_name => 'NewFoo' }),
        "Create event type" );
    ok( my @meths = $et->my_meths(0, 1), "Get ident meths" );
    is( scalar @meths, 1, "Check for 1 meth" );
    is( $meths[0]->{name}, 'key_name', "Check for 'key_name' meth" );
    is( $meths[0]->{get_meth}->($et), 'NewFoo', "Check name 'NewFoo'" );
}

1;
__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl -w
use Bric::Util::EventType;
use Test;


BEGIN { plan tests => 56 }

eval {
    if (@ARGV) {
    print "Fetching EventType 1024.\n";
    my $et = Bric::Util::EventType->lookup({id => 1029});
    print "ID:      ", $et->get_id, "\n";
    print "Class:   ", $et->get_class, "\n";
    print "KeyName: ", $et->get_key_name, "\n";
    print "Name:    ", $et->get_name, "\n";
    print "Desc:    ", $et->get_description, "\n";
    print "Active:  ", $et->is_active ? "Yes\n\n" : "No\n\n";
    print "Getting its attributes.\n";
    print "Attr:    ", $et->get_attr ? "Yes\n\n" : "No\n\n";

    print "Getting a list of all event types for stories.\n";
    foreach my $et ( Bric::Util::EventType->list(
          {class => 'Bric::Biz::Asset::Business::Story'}) ) {
        print "ID:      ", $et->get_id, "\n";
        print "Class:   ", $et->get_class, "\n";
        print "KeyName: ", $et->get_key_name, "\n";
        print "Name:    ", $et->get_name, "\n";
        print "Desc:    ", $et->get_description, "\n\n";
    }

    print "Getting a list of Story event type IDs.\n";
    my $ids = Bric::Util::EventType->list_ids(
          {class => 'Bric::Biz::Asset::Business::Story'});
    local $" = ', ';
    print "IDs: @$ids\n\n";

    print "Getting a list of classes for which types of events have been defined.\n";
    my $classes = Bric::Util::EventType->list_classes;
    while (my ($pkg, $dis) = each %$classes) {
        print "$dis: $pkg\n";
    }
    print "\n";
    exit;
    }

    # Now, the Test::Harness code.
    exit;
};

if (my $err = $@) {
    print "Error: ", ref $err ? $err->get_msg . ":\n\n" . $err->get_payload
      . "\n" : "$err\n";
}
