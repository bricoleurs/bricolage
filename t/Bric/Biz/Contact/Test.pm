package Bric::Biz::Contact::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Biz::Contact');
}

1;
__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl -w
use Test;

BEGIN { plan tests => 48 }

use Bric;
use Bric::BC::Contact;

eval {

if (@ARGV) {
    print "Getting a list of contact types.\n";
    local $" = ', ';
    print "@{Bric::BC::Contact->list_types}\n\n";

    print "Getting a list of alertable contact types\n";
    print "@{Bric::BC::Contact->list_alertable_types}\n\n";

    print "Adding, changing, and deleting types.\n";
    Bric::BC::Contact->edit_type('Smoke Signals', 'Very Old Contact Type');
    Bric::BC::Contact->edit_type('Primary Email', 'Neuvo Electronica');
    Bric::BC::Contact->deactivate_type('WWW');


    print "Getting a hashref of contact types\n";
    my $types = Bric::BC::Contact->href_types;
    while (my ($t, $d) = each %$types) {
	print "$t => $d\n";
    }
    print "\n";

    print "Getting alertable types and thier IDs.\n";
    $types = Bric::BC::Contact->href_alertable_type_ids;
    while (my ($k, $v) = each %$types) { print "$v => $k\n" }
    print "\n";

    print "Getting a hashref of alertable contact types\n";
    $types = Bric::BC::Contact->href_alertable_types;
    while (my ($t, $d) = each %$types) {
	print "$t => $d\n";
    }
    print "\n";

    print "Returning changed contacts to normal.\n";
    Bric::BC::Contact->edit_type('Primary Email', 'Electronic Mail');
    Bric::BC::Contact->edit_type('WWW', 'WWW URL');
    Bric::Util::DBI::prepare_c(qq{
        DELETE FROM contact
        WHERE  id > 1023
    })->execute;

    print "Fetching an existing contact.\n";
    my $c = Bric::BC::Contact->lookup({id => 1});
    print "ID:          ", $c->get_id || '', "\n";
    print "Type:        ", $c->get_type || '', "\n";
    print "Description: ", $c->get_description || '', "\n";
    print "Value:       ", $c->get_value || '', "\n\n";

    print "Creating a new Contact.\n";
    $c = Bric::BC::Contact->new({type => 'ICQ ID', value => '15726394'});
    print "Type:        ", $c->get_type || '', "\n";
    print "Description: ", $c->get_description || '', "\n";
    print "Value:       ", $c->get_value || '', "\n\n";

    print "Saving the new Contact.\n";
    $c->save;

    print "Changing settings and saving again.\n";
    $c->set_type('Pager Email');
    $c->set_value('my_pager@nextel.com');
    $c->save;

    print "Type:        ", $c->get_type || '', "\n";
    print "Description: ", $c->get_description || '', "\n";
    print "Value:       ", $c->get_value || '', "\n\n";

    print "Deleting contact.\n";
    $c->deactivate;
    $c->save;
    print "ID:          ", $c->get_id || '', "\n";

    print "Fetching a few contacts...those that are phones.\n";
    foreach my $c (Bric::BC::Contact->list({type => '%phone%'})) {
	print "ID:          ", $c->get_id || '', "\n";
	print "Type:        ", $c->get_type || '', "\n";
	print "Description: ", $c->get_description || '', "\n";
	print "Value:       ", $c->get_value || '', "\n\n";
    }

    print "Fetching mobile phones in the 415 area code.\n";
    foreach my $c (Bric::BC::Contact->list({type => 'Mobile Phone',
							  value => '(415)%'})) {
	print "ID:          ", $c->get_id || '', "\n";
	print "Type:        ", $c->get_type || '', "\n";
	print "Description: ", $c->get_description || '', "\n";
	print "Value:       ", $c->get_value || '', "\n\n";
    }

    print "Fetching the IDs of those contacts that are messenger IDs.\n";
    print "\t$_\n" for Bric::BC::Contact->list_ids({description => '%messenger%'});
    print "\n";

    Bric::Util::DBI::prepare_c(qq{
        DELETE FROM contact_value
        WHERE  id > 1023
    })->execute;
    exit
}

# Looking up an existing contact. 1-5.
ok my $c = Bric::BC::Contact->lookup({id => 1});
ok $c->get_id;
ok $c->get_type;
ok $c->get_description;
ok $c->get_value;

# "Creating a new Contact. 6-10.
ok $c = Bric::BC::Contact->new({type => 'ICQ ID', value => '15726394'});
ok !$c->get_id;
ok $c->get_type;
ok $c->get_value;
ok !$c->get_description;

# Save it. 11-12.
ok $c->save;
ok $c->get_id;

# Change it. 13-18.
ok $c->set_type('Pager Email');
ok $c->set_value('my_pager@nextel.com');
ok $c->save;
ok $c->get_type;
ok $c->get_value;
ok !$c->get_description;

# Delete it. 19-21.
ok $c->deactivate;
ok $c->save;
ok $c->get_id;

# Fetch all the phones and check two of them. 22-30.
ok my @c = Bric::BC::Contact->list({type => '%phone%'});
ok $c[0]->get_id;
ok $c[0]->get_type;
ok $c[0]->get_description;
ok $c[0]->get_value;
ok $c[1]->get_id;
ok $c[1]->get_type;
ok $c[1]->get_description;
ok $c[1]->get_value;

# Fetch mobile phones in the 415 area code and check two of them. 31-39.
ok @c = Bric::BC::Contact->list({type => 'Mobile Phone',
			       value => '(415)%'});
ok $c[0]->get_id;
ok $c[0]->get_type;
ok $c[0]->get_description;
ok $c[0]->get_value;
ok $c[1]->get_id;
ok $c[1]->get_type;
ok $c[1]->get_description;
ok $c[1]->get_value;

# Fetch messenger IDs. 40.
ok my @ids = Bric::BC::Contact->list_ids({description => '%messenger%'});

# Get a type lists. 41-42.
ok my @types = Bric::BC::Contact->list_types;
ok @types = Bric::BC::Contact->list_alertable_types;

# Add, change, and delete types. 43-46.
ok( Bric::BC::Contact->edit_type('Smoke Signals', 'Very Old Contact Type') );
ok( Bric::BC::Contact->edit_type('Primary Email', 'Neuvo Electronica') );
ok( Bric::BC::Contact->edit_type('Primary Email', 'Primary Electronic Mail Address') );
ok( Bric::BC::Contact->deactivate_type('WWW') );

# Get hashrefs of types. 47-48.
ok my $types = Bric::BC::Contact->href_types;
ok $types = Bric::BC::Contact->href_alertable_types;

# Cleanup.
Bric::Util::DBI::prepare_c(qq{
    DELETE FROM contact
    WHERE  id > 1023
})->execute;

Bric::Util::DBI::prepare_c(qq{
    DELETE FROM contact_value
    WHERE  id > 1023
})->execute;

};

if (my $err = $@) {
    print "Error: ", ref $err ? $err->get_msg . ":\n\n" . $err->get_payload
      . "\n" : "$err\n";
}
