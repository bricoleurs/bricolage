package Bric::Util::Alerted::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Util::Alerted');
}

1;
__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl -w
use Bric::Util::Alerted;
use Test;

BEGIN { plan tests => 56 }

eval {
    if (@ARGV) {
	print "Getting all Alerteds for Alert #!\n";
	foreach my $ald
	  (Bric::Util::Alerted->list({ alert_id => 1 })) {
	      print "ID:       ", $ald->get_id, "\n";
	      print "User ID:  ", $ald->get_user_id, "\n";
	      print "User:     ", ref $ald->get_user, "\n";
	      print "Alert ID: ", $ald->get_alert_id, "\n";
	      print "Alert:    ", ref $ald->get_alert, "\n";
	      print "Ack:      ", $ald->get_ack_time("%D") || '', "\n";
	      print "Meths:\n";
	      foreach my $meth ($ald->get_sent) {
		  print "  Method:  ", $meth->get_type, "\n";
		  print "  Contact: ", $meth->get_value, "\n";
		  print "  Time:    ", $meth->get_sent_time("%D %T"), "\n\n";
	      }
	}

	print "Getting a list of IDs for Alert #1\n";
	my $ids = Bric::Util::Alerted->list_ids({ alert_id => 1 });
	local $" = ', ';
	print "IDS: @$ids\n";

	print "Retrieving Alerted #3.\n";
	my $ald = Bric::Util::Alerted->lookup({ id => 3 });
	print "ID:       ", $ald->get_id, "\n";
	print "User ID:  ", $ald->get_user_id, "\n";
	print "User:     ", ref $ald->get_user, "\n";
	print "Alert ID: ", $ald->get_alert_id, "\n";
	print "Alert:    ", ref $ald->get_alert, "\n";
	print "Ack:      ", $ald->get_ack_time("%D") || '', "\n";
	print "Meths:\n";
	foreach my $meth ($ald->get_sent) {
	    print "  Method:  ", $meth->get_type, "\n";
	    print "  Contact: ", $meth->get_value, "\n";
	    print "  Time:    ", $meth->get_sent_time("%D %T"), "\n\n";
	}

	print "Acknowledging Alerted #3.\n";
	$ald->acknowledge;
	print "Ack:      ", $ald->get_ack_time("%D %T") || '', "\n\n";

	print "Removing acknowledgement so future testing will work.\n";
	Bric::Util::DBI::prepare(qq{
            UPDATE alerted
            SET    ack_time = NULL
            WHERE  id = 3
        })->execute;
	print "Done!\n";

	exit;


    }

    # Now, the Test::Harness code.
    exit;
};

print "Error: $@" if $@;
