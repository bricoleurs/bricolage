package Bric::Util::AlertType::Test;
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
    use_ok('Bric::Util::AlertType');
}


__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl -w
use Bric::Util::AlertType;
use Test;

BEGIN { plan tests => 56 }

eval {
    if (@ARGV) {

	print "Getting all ATs for password changes.\n";
	foreach my $at
	  (Bric::Util::AlertType->list({ event_type_id => 1028})) {
	      print "ID:       ", $at->get_id, "\n";
	      print "Owner ID: ", $at->get_owner_id, "\n";
	      print "ET ID:    ", $at->get_event_type_id, "\n";
	      print "Name:     ", $at->get_name, "\n";
	      print "Subject:  ", $at->get_subject, "\n";
	      print "Message:  ", $at->get_message, "\n";
	      print "Active:   ", $at->is_active ? 'Yes' : 'No', "\n\n";
	}
	print "Getting all AT IDs for User #3\n";
	local $" = ', ';
	print "IDs: @{ Bric::Util::AlertType->list_ids({ owner_id => 3}) }\n\n";

	print "Creating a new AT.\n";
	my $at = Bric::Util::AlertType->new;
	$at->set_owner_id(1);
	$at->set_event_type_id(1024);
	$at->set_name('Testing!');
	$at->set_subject('Test Subject');
	$at->set_message('Test Message');

	print "ID:       ", $at->get_id || '', "\n";
	print "Owner ID: ", $at->get_owner_id, "\n";
	print "ET ID:    ", $at->get_event_type_id, "\n";
	print "Name:     ", $at->get_name, "\n";
	print "Subject:  ", $at->get_subject, "\n";
	print "Message:  ", $at->get_message, "\n";
	print "Active:   ", $at->is_active ? 'Yes' : 'No', "\n\n";

	print "Saving and reloading the new AT\n";
	$at->save;
	$at = Bric::Util::AlertType->lookup({ id => $at->get_id });
	print "ID:       ", $at->get_id || '', "\n";
	print "Owner ID: ", $at->get_owner_id, "\n";
	print "ET ID:    ", $at->get_event_type_id, "\n";
	print "Name:     ", $at->get_name, "\n";
	print "Subject:  ", $at->get_subject, "\n";
	print "Message:  ", $at->get_message, "\n";
	print "Active:   ", $at->is_active ? 'Yes' : 'No', "\n\n";

	print "Getting alert type #1\n";
	$at = Bric::Util::AlertType->lookup({ id => 1 });
	print "ID:       ", $at->get_id, "\n";
	print "Owner ID: ", $at->get_owner_id, "\n";
	print "Owner:    ", ref $at->get_owner, "\n";
	print "ET ID:    ", $at->get_event_type_id, "\n";
	print "ET:       ", ref $at->get_event_type, "\n";
	print "Name:     ", $at->get_name, "\n";
	print "Subject:  ", $at->get_subject, "\n";
	print "Message:  ", $at->get_message, "\n";
	print "Active:   ", $at->is_active ? 'Yes' : 'No', "\n\n";

	print "Adding a rule to AT #1.\n";
	my $r = $at->new_rule('thingy', 'ne', 'hah!');
	$at->save;

	print "Getting AT #1's rules.\n";
	foreach my $rule ($at->get_rules) {
	      print "ID:      ", $rule->get_id || '', "\n";
	      print "AT ID:   ", $rule->get_alert_type_id, "\n";
	      print "Attr:    ", $rule->get_attr, "\n";
	      print "Op:      ", $rule->get_operator, "\n";
	      print "Value:   ", $rule->get_value, "\n\n";
	}

	print "Deleting the rule just created.\n";
	$at->del_rules($r->get_id);
	$at->save;

	print "Getting AT #1's contacts.\n";
	foreach my $ctype ('Primary Email', 'Pager Email', 'AIM ID') {
	    print "Contacts by $ctype:\n";
	    local $" = ', ';
	    print "\tUser IDs: @{ $at->get_user_ids($ctype) }\n";
	    print "\tUsers: @{ $at->get_users($ctype) }\n";
	    print "\tGroup IDs: @{ $at->get_grp_ids($ctype) }\n";
	    print "\tGroups: @{ $at->get_grps($ctype) }\n";
	}
	print "\n";

	print "Adding Primary Email contacts for AT #1 and reloading.\n";
	$at->add_users('Primary Email', 3, 4);
	$at->add_grps('Primary Email', 204, 205);
	$at->save;
	$at = Bric::Util::AlertType->lookup({ id => 1 });

	print "Getting AT #1's Primary Email contacts again.\n";
	local $" = ', ';
	print "\tUser IDs: @{ $at->get_user_ids('Primary Email') }\n";
	print "\tGroup IDs: @{ $at->get_grp_ids('Primary Email') }\n";
	print "\n";

	print "Now deleting the contacts just added and reloading again.\n";
	$at->del_users('Primary Email', 3, 4);
	$at->del_grps('Primary Email', 4, 5);
	$at->save;
	$at = Bric::Util::AlertType->lookup({ id => 1 });

	print "Getting AT #1's Primary Email contacts one final time.\n";
	local $" = ', ';
	print "\tUser IDs: @{ $at->get_user_ids('Primary Email') }\n";
	print "\tGroup IDs: @{ $at->get_grp_ids('Primary Email') }\n";
	print "\n";

	print "Deleting bogus records.\n";
	Bric::Util::DBI::prepare(qq{
            DELETE FROM alert_type
            WHERE  id > 1023
        })->execute;
	print "Done!\n";
	exit;
    }

    # Now, the Test::Harness code.
    exit;
};

if (my $err = $@) {
    print "Error: ", ref $err ? $err->get_msg . ":\n\n" . $err->get_payload
      . "\n" : "$err\n";
}
