#!/usr/bin/perl -w
use Bric::BC::Org;

eval {

    if (@ARGV) {
	# Create a brand new Org:
	print "Creating new Org...\n";
	my $o1 = Bric::BC::Org->new({name => 'Kodak',
				   long_name => 'Eastman Kodak, Inc.'});

	# Prove we've created it.
	print "ID:       ", $o1->get_id || '', "\n";
	print "Name:     ", $o1->get_name || '', "\n";
	print "LName:    ", $o1->get_long_name || '', "\n";
	print "Personal: ", $o1->is_personal ? 'Yes' : 'No', "\n";
	print "Active:   ", $o1->is_active || '', "\n\n";

	# Save it and print the ID again:
	print "Saving...\n";
	$o1->save;
	print "ID:     ", $o1->get_id || '', "\n\n";

	# Grab existing org.
	print "Grabbing Existing Org ID 1\n";
	my $o2 = Bric::BC::Org->lookup({id => 1});
	# Reset some of its properties.
	$o2->set_name('IBM');
	$o2->set_long_name('International Business Machine');
	$o2->deactivate;
	$o2->save;

	# This should fail:
	print "This should be an error message:\n";
	eval { $o2->set_id(22) };
	print "Error: $@\n\n";

	# Okay, grab him again.
	print "Grabbing 1 from the database again.\n";
	$o2 = Bric::BC::Org->lookup({id => 1});

	# Now print them the properties.
	print "ID:     ", $o2->get_id || '', "\n";
	print "Name:   ", $o2->get_name || '', "\n";
	print "LName:  ", $o2->get_long_name || '', "\n";
	print "Active: ", $o2->is_active || '', "\n\n";

	# Reactivate the org and reset its values.
	$o2->set_name('About');
	$o2->set_long_name('About Internet');
	$o2->activate;
	$o2->save;

	# Okay, let's see if we can see the addresses!
	print "Fetching the addresses.\n";
	foreach my $addr ($o2->get_addr) {
	    print "ID: ", $addr->get_id, "\n";
	    print "Type: ", $addr->get_type, "\n";
	    map { print "$_\n" } $addr->get_lines;
	    print $addr->get_city, ", ", $addr->get_state, "\n";
	    print $addr->get_code || '', "  ", $addr->get_country || '', "\n\n";
	}

	print "Adding an address.\n";
	my $addr = $o2->new_addr;
	$addr->set_type('Temp');
	$addr->set_lines('483 18th Street', 'Suite 24');
	$addr->set_city('East Lansing');
	$addr->set_state('MI');
	$addr->set_code('59685');
	$addr->set_country('Canada');

	$o2->save;

	print "Fetching addresses again.\n";
	foreach my $addr ($o2->get_addr) {
	    print "ID: ", $addr->get_id, "\n";
	    print "Type: ", $addr->get_type, "\n";
	    map { print "$_\n" } $addr->get_lines;
	    print $addr->get_city, ", ", $addr->get_state, "\n";
	    print $addr->get_code || '', "  ", $addr->get_country || '', "\n\n";
	}

	print "Deleting an address...\n";
	foreach my $addr ($o2->get_addr) {
	    my $id = $addr->get_id;
	    $o2->del_addr($id) if $id > 1023;
	}

	$o2->save;

	print "Fetching addresses again.\n";
	foreach my $addr ($o2->get_addr) {
	    print "ID: ", $addr->get_id, "\n";
	    print "Type: ", $addr->get_type, "\n";
	    map { print "$_\n" } $addr->get_lines;
	    print $addr->get_city, ", ", $addr->get_state, "\n";
	    print $addr->get_code || '', "  ", $addr->get_country || '', "\n\n";
	}

	print "Grabbing a single address.\n";
	($addr) = $o2->get_addr(1);
	print "ID: ", $addr->get_id, "\n";
	print "Type: ", $addr->get_type, "\n";
	map { print "$_\n" } $addr->get_lines;
	print $addr->get_city, ", ", $addr->get_state, "\n";
	print $addr->get_code, "  ", $addr->get_country, "\n\n";

	print "Grabbing two addresses.\n";
	foreach my $addr ($o2->get_addr(1,2) ) {
	    print "ID: ", $addr->get_id, "\n";
	    print "Type: ", $addr->get_type, "\n";
	    map { print "$_\n" } $addr->get_lines;
	    print $addr->get_city, ", ", $addr->get_state, "\n";
	    print $addr->get_code, "  ", $addr->get_country, "\n\n";
	}

	print "Grabbing all Red IDs\n";
	my @ids = Bric::BC::Org->list_ids({name => 'Red%'});
	print "IDs: @ids\n";

	print "Grabbing all Red organizations. (The commies!)\n";
	foreach my $o3 (Bric::BC::Org->list({name => 'Red%'})) {
	    print "ID:     ", $o3->get_id || '', "\n";
	    print "Name:   ", $o3->get_name || '', "\n";
	    print "LName:  ", $o3->get_long_name || '', "\n";
	    print "Active: ", $o3->is_active || '', "\n\n";
	}

	exit;
	# Okay, delete the bogus record we created at the top.
	print "Deleting bogus records.\n";
	Bric::Util::DBI::prepare(qq{
            DELETE FROM org
            WHERE  name = 'Kodak'
        })->execute;

	Bric::Util::DBI::prepare(qq{
            DELETE FROM addr_part
            WHERE  id > 1023
        })->execute;

	Bric::Util::DBI::prepare(qq{
            DELETE FROM addr_part_type
            WHERE  id > 1023
        })->execute;

	Bric::Util::DBI::prepare(qq{
            DELETE FROM addr
            WHERE  id > 1023
        })->execute;
	print "Done!\n";
    }

    # Do Test::Harness testing here.
};

if (my $err = $@) {
    if (ref $err) {
	print "Error: ", $err->get_msg, ": ", $err->get_payload, "\n";
    } else {
	print "Error: $err\n";
    }
}
