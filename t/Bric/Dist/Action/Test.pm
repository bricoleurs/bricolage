package Bric::Dist::Action::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Dist::Action');
}

1;
__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl -w
use Test;
use Bric::Dist::Action;

BEGIN { plan tests => 10 }

eval {

    if (@ARGV) {
	# Do verbose testing here.
	my $action;

	print "Getting Action #1.\n";
	$action = Bric::Dist::Action->lookup({ id => 1 });
	print "ID:         ", $action->get_id || '', "\n";
	print "Type:       ", $action->get_type || '', "\n";
	print "Order:      ", $action->get_ord || '', "\n";
	print "Class:      ", ref $action, "\n";
	print "Desc:       ", $action->get_description || '', "\n";
	print "ServerType: ", $action->get_server_type_id || '', "\n";
	print "MEDIA Types:";
	if (my @medias = $action->get_media_types) {
	    print "\n  $_" for @medias;
	} else {
	    print " All.";
	}
	print "\n\n";

	print "Getting all actions associated with Server Type #2\n";
	foreach my $action (Bric::Dist::Action->list({ server_type_id => 2 })) {
	    print "ID:         ", $action->get_id || '', "\n";
	    print "Type:       ", $action->get_type || '', "\n";
	    print "Order:      ", $action->get_ord || '', "\n";
	    print "Class:      ", ref $action, "\n";
	    print "Desc:       ", $action->get_description || '', "\n";
	    print "ServerType: ", $action->get_server_type_id || '', "\n";
	    print "MEDIA Types:";
	    if (my @medias = $action->get_media_types) {
		print "\n  $_" for @medias;
	    } else {
		print " All.";
	    }
	    print "\n\n";
	}

	print "Getting href or all actions associated with Server Type #1\n";
	my $href = Bric::Dist::Action->href({ server_type_id => 1 });
	while(my ($id, $action) = each %$href ) {
	    print "ID:         $id\n";
	    print "Type:       ", $action->get_type || '', "\n";
	    print "Order:      ", $action->get_ord || '', "\n";
	    print "Class:      ", ref $action, "\n";
	    print "Desc:       ", $action->get_description || '', "\n";
	    print "ServerType: ", $action->get_server_type_id || '', "\n";
	    print "MEDIA Types:";
	    if (my @medias = $action->get_media_types) {
		print "\n  $_" for @medias;
	    } else {
		print " All.";
	    }
	    print "\n\n";
	}

	print "Getting all action IDs with an action type 'Move.'\n";
	{
	    local $" = ', ';
	    print "IDs: @{ Bric::Dist::Action->list_ids({ type => 'Move' })}\n\n";
        }

	print "Creating a new Akamaize action.\n";
#	$action = Bric::Dist::Action->new({ type => 'Akamaize' });
	$action = Bric::Dist::Action->new;
	$action->set_type("Akamaize");
	$action->set_server_type_id(2);
	$action->save;
	print "Class:      ", ref $action || '', "\n";
	print "ID:         ", $action->get_id || '', "\n";
	print "Type:       ", $action->get_type || '', "\n";
	print "Order:      ", $action->get_ord || '', "\n";
	print "Class:      ", ref $action, "\n";
	print "Desc:       ", $action->get_description || '' || '', "\n";
	print "ServerType: ", $action->get_server_type_id || '' || '', "\n";

	print "Getting Akamaize Action #1\n";
	$action = Bric::Dist::Action->lookup({ id => 1 });
	print "ID:         ", $action->get_id || '', "\n";
	print "Type:       ", $action->get_type || '', "\n";
	print "Order:      ", $action->get_ord || '', "\n";
	print "Class:      ", ref $action, "\n";
	print "Desc:       ", $action->get_description || '', "\n";
	print "ServerType: ", $action->get_server_type_id || '', "\n";
	$action->set_dns_name('www.about.com');
	$action->set_cp_code('coder');
	$action->set_seed_a('seedy');
	$action->set_seed_b('ydees');
	print "DNS Name: ", $action->get_dns_name || '', "\n";
	print "CP Code:  ", $action->get_cp_code || '', "\n";
	print "Seed A:   ", $action->get_seed_a || '', "\n";
	print "Seed B:   ", $action->get_seed_b || '', "\n\n";
	$action->save;

	$action = Bric::Dist::Action->lookup({ id => 1 });
	print "DNS Name: ", $action->get_dns_name || '', "\n";
	print "CP Code:  ", $action->get_cp_code || '', "\n";
	print "Seed A:   ", $action->get_seed_a || '', "\n";
	print "Seed B:   ", $action->get_seed_b || '', "\n\n";

	print "Clearing attributes.\n";
	$action->_clear_attr;

	print "Cleaning up bogus records.\n";
        Bric::Util::DBI::prepare_c(qq{
            DELETE FROM attr_action
            WHERE  id > 1023
        })->execute;

        Bric::Util::DBI::prepare_c(qq{
            DELETE FROM action
            WHERE  id > 1023
        })->execute;

	print "Done!\n";
	exit;
    }

    # Do Test::Harness testing here.


    exit;
};

print "Error: $@" if $@;

