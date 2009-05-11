package Bric::Util::Event::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Util::Event');
}

1;
__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl -w
use Bric::Util::Event;
use Bric::Biz::Person::User;
use Bric::Biz::Workflow;
use Test;


BEGIN { plan tests => 56 }

eval {
    if (@ARGV) {

    print "Creating a new event.\n";
#    my $p = Bric::Biz::Person::User->lookup({ id => 1 });
    my $p = Bric::Biz::Workflow->lookup({ id => 1025 });
    my $trig = Bric::Biz::Person::User->lookup({ id => 4 });
    my $event = Bric::Util::Event->new({ key_name => 'workflow_add_desk',
                       obj => $p,
                       user => $trig,
                       attr => { Desk => 'Bogus Desk' }
                     });

    print "ID:      ", $event->get_id, "\n";
    print "Name:    ", $event->get_name, "\n";
    print "KeyName: ", $event->get_key_name, "\n";
    print "Desc:    ", $event->get_description, "\n";
    print "User ID: ", $event->get_user_id, "\n";
    print "Obj ID:  ", $event->get_obj_id, "\n";
    print "Time:    ", $event->get_timestamp, "\n";
    print "Class:   ", $event->get_class, "\n";
    print "Type:    ", $event->get_event_type_id, "\n\n";
    my $attr = $event->get_attr || {};
    while (my ($k, $v) = each %$attr) { print "Attr:    $k => $v\n" }
    print "\n";

    print "Looking up Event #1.\n";
    $event = Bric::Util::Event->lookup({ id => 11 });
    print "ID:      ", $event->get_id, "\n";
    print "Name:    ", $event->get_name, "\n";
    print "KeyName: ", $event->get_key_name, "\n";
    print "Desc:    ", $event->get_description, "\n";
    print "User ID: ", $event->get_user_id, "\n";
    print "Obj ID:  ", $event->get_obj_id, "\n";
    print "Time:    ", $event->get_timestamp, "\n";
    print "Class:   ", $event->get_class, "\n";
    print "Type:    ", $event->get_event_type_id, "\n\n";
    $attr = $event->get_attr || {};
    while (my ($k, $v) = each %$attr) { print "Attr:    $k => $v\n" }
    print "\n";
exit;
    print "Finding all event logged for User #3\n";
    foreach my $event (Bric::Util::Event->list({obj_id => 3, class_id => 2})) {
        print "ID:      ", $event->get_id, "\n";
        print "Name:    ", $event->get_name, "\n";
        print "KeyName: ", $event->get_key_name, "\n";
        print "User ID: ", $event->get_user_id, "\n";
        print "Obj ID:  ", $event->get_obj_id, "\n";
        print "Time:    ", $event->get_timestamp, "\n\n";
    }

    print "Looking up all events triggered by User #3\n";
    foreach my $event (Bric::Util::Event->list({user_id => 3})) {
        print "ID:      ", $event->get_id, "\n";
        print "Name:    ", $event->get_name, "\n";
        print "KeyName: ", $event->get_key_name, "\n";
        print "User ID: ", $event->get_user_id, "\n";
        print "Obj ID:  ", $event->get_obj_id, "\n";
        print "Time:    ", $event->get_timestamp, "\n\n";
    }
    exit;
    }

    # Now, the Test::Harness code.
    exit;
};

print "Error: $@\n" if $@;
