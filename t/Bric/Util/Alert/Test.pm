package Bric::Util::Alert::Test;
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
    use_ok('Bric::Util::Alert');
}


__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl -w
use Bric::Util::Event;
use Bric::Util::Alert;
use Bric::Util::AlertType;
use Bric::Biz::Person::User;
use Test;

BEGIN { plan tests => 56 }

eval {
    if (@ARGV) {
	print "Looking up existing Alert #1.\n";
	my $alert = Bric::Util::Alert->lookup({ id => 1 });
	print "ID:       ", $alert->get_id, "\n";
	print "AT ID:    ", $alert->get_alert_type_id, "\n";
	print "AT:       ", ref $alert->get_alert_type, "\n";
	print "Event ID: ", $alert->get_event_id, "\n";
	print "Event:    ", ref $alert->get_event, "\n";
	print "Subject:  ", $alert->get_subject, "\n";
	print "Message:  ", $alert->get_message, "\n";
	print "Time:     ", $alert->get_timestamp('%D'), "\n\n";

	print "Getting all alerts with alert_type_id 1.\n";
	foreach my $alert
	  (Bric::Util::Alert->list({ alert_type_id => 1 })) {
	    print "ID:       ", $alert->get_id, "\n";
	    print "AT ID:    ", $alert->get_alert_type_id, "\n";
	    print "Event ID: ", $alert->get_event_id, "\n";
	    print "Subject:  ", $alert->get_subject, "\n";
	    print "Message:  ", $alert->get_message, "\n";
	    print "Time:     ", $alert->get_timestamp, "\n\n";
	}

	print "Creating a new alert.\n";
	my $at = Bric::Util::AlertType->lookup({id => 2});
	my $event = Bric::Util::Event->lookup({id => 3});
	my $obj = Bric::Biz::Person::User->lookup({ id => 2 });
	my $user= Bric::Biz::Person::User->lookup({ id => 2 });
	$at->add_users('Primary Email', 3);
	$at->send_alerts({event => $event,
			  obj => $obj,
			  user => $user });
	exit;
	print "Deleting bogus records.\n";
	Bric::Util::DBI::prepare(qq{
            DELETE FROM alert
            WHERE  id > 1023
        })->execute;
	print "Done!\n";
	exit;


    }

    # Now, the Test::Harness code.
    exit;
};

print "Error: $@" if $@;
