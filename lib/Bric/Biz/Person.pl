#!/usr/bin/perl -w
use Bric;
use Bric::BC::Person;
use Test;
#$Bric::Cust = 'sharky';


BEGIN { plan tests => 64 }

eval {

if (@ARGV) {
# Create a brand new Person:
print "Creating new Person...\n";
my $p1 = Bric::BC::Person->new({lname => 'Wheeler',
			      fname => 'David',
			      suffix => 'MA',
			      prefix => 'Mr.',
			      mname => 'Erin'});

# Prove we've created it.
print "ID:     ", $p1->get_id || '', "\n";
print "LName:  ", $p1->get_lname || '', "\n";
print "FName:  ", $p1->get_fname || '', "\n";
print "MName:  ", $p1->get_mname || '', "\n";
print "Prefix: ", $p1->get_prefix || '', "\n";
print "Suffix: ", $p1->get_suffix || '', "\n";
print "Active: ", $p1->is_active || '', "\n";
print "Name:   ", $p1->format_name, "\n\n";

# Save it and print the ID again:
print "Saving...\n";
$p1->save;
print "ID:     ", $p1->get_id || '', "\n\n";

# Grab existing user.
print "Grabbing Existing User ID 1\n";
my $p2 = Bric::BC::Person->lookup({id => 1});
# Reset some of its properties.
$p2->set_lname('Whorf');
$p2->set_fname('Benjamin');
$p2->set_mname('Lee');
$p2->set_prefix('Dr.');
$p2->set_suffix('Ph.D');
$p2->deactivate;
$p2->save;

# This should fail:
#eval { $p2->set_id(22) };
if (my $err = $@) {
    print "Error: ", ref $err ? $err->get_msg . ":\n\n" . $err->get_payload
      . "\n" : "$err\n";
}

# Okay, grab him again.
print "Grabbing 1 from the database again.\n";
$p2 = Bric::BC::Person->lookup({id => 1});

# Now print them the properties.
print "ID:     ", $p2->get_id || '', "\n";
print "LName:  ", $p2->get_lname || '', "\n";
print "FName:  ", $p2->get_fname || '', "\n";
print "MName:  ", $p2->get_mname || '', "\n";
print "Prefix: ", $p2->get_prefix || '', "\n";
print "Suffix: ", $p2->get_suffix || '', "\n";
print "Active: ", $p2->is_active || '', "\n";
print "Name:   ", $p2->format_name("%p% f% M% l%, s"), "\n\n";

# Reactivate the user and reset its values.
$p2->set_lname('Yoo');
$p2->set_fname('Ayeta');
$p2->set_mname('Alla');
$p2->set_prefix('Mr.');
$p2->set_suffix;
$p2->activate;
$p2->save;

print "Getting groups.\n";
print "Group:    ", $_->get_name, "\n" for $p2->get_grps;
print "\n";

print "Getting group IDs.\n";
print "Group ID: ", $_, "\n" for $p2->get_grp_ids;
print "\n";


print "Getting Person ID 2.\n";
my $per = Bric::BC::Person->lookup({ id => 2});
print "Getting Contacts for ID 2.\n";
foreach my $c ($per->get_contacts) {
    print "ID:    ", $c->get_id || '', "\n";
    print "Type:  ", $c->get_type || '', "\n";
    print "Value: ", $c->get_value || '', "\n";
    print "Active: ", $c->is_active ? 'Yes' : 'No', "\n";
} print "\n";

print "Adding a contact to ID 2 and fetching again.\n";
my $c = $per->new_contact('Pager', '(510) 896-9569');
$per->save;

foreach my $c ($per->get_contacts) {
    print "ID:     ", $c->get_id || '', "\n";
    print "Type:   ", $c->get_type || '', "\n";
    print "Value:  ", $c->get_value || '', "\n";
    print "Active: ", $c->is_active ? 'Yes' : 'No', "\n";
} print "\n";

print "Deleting a contact from ID 2.\n";
$per->del_contacts($c->get_id);
$per->save;
foreach my $c ($per->get_contacts) {
    print "ID:    ", $c->get_id || '', "\n";
    print "Type:  ", $c->get_type || '', "\n";
    print "Value: ", $c->get_value || '', "\n";
    print "Active: ", $c->is_active ? 'Yes' : 'No', "\n";
} print "\n";


print "Grabbing all Wheeler IDs\n";
my $ids = Bric::BC::Person->list_ids({lname => 'Wheeler', fname => 'David'});
print "IDs: @$ids\n";


print "Grabbing all Wheelers!\n";
foreach my $p3 (Bric::BC::Person->list({lname => 'Wheeler', fname => 'David'})) {
    print "ID:     ", $p3->get_id || '', "\n";
    print "LName:  ", $p3->get_lname || '', "\n";
    print "FName:  ", $p3->get_fname || '', "\n";
    print "MName:  ", $p3->get_mname || '', "\n";
    print "Prefix: ", $p3->get_prefix || '', "\n";
    print "Suffix: ", $p3->get_suffix || '', "\n";
    print "Active: ", $p3->is_active || '', "\n";
    print "Name:   ", $p3->format_name("%p% f% M% l%, s"), "\n\n";
}

# Okay, delete the bogus record we created at the top.
print "Deleting bogus records.\n";
Bric::Util::DBI::prepare(qq{
    DELETE FROM person
    WHERE  id > 1023
})->execute;

Bric::Util::DBI::prepare(qq{
    DELETE FROM contact_value
    WHERE  id > 1023
})->execute;

Bric::Util::DBI::prepare(qq{
    DELETE FROM org
    WHERE  id > 1023
})->execute;

print "Done!\n";
exit;
}

# Now, the Test::Harness code.
# Create a new person.
ok my $p1 = Bric::BC::Person->new({lname => 'Wheeler',
			      fname => 'David',
			      suffix => 'MA',
			      prefix => 'Mr.',
			      mname => 'Erin'});

# Prove we've created it. 1-9.
ok !$p1->get_id;
ok $p1->get_lname;
ok $p1->get_fname;
ok $p1->get_mname;
ok $p1->get_prefix;
ok $p1->get_suffix;
ok $p1->is_active;
ok $p1->format_name("%p% f% M% l%, s");

# Now save it. 10-11.
ok $p1->save;
ok $p1->get_id;

# Grab existing user. 12.
ok my $p2 = Bric::BC::Person->lookup({id => 1});

# Reset some of its properties. 13-19.
ok $p2->set_lname('Whorf');
ok $p2->set_fname('Benjamin');
ok $p2->set_mname('Lee');
ok $p2->set_prefix('Dr.');
ok $p2->set_suffix('Ph.D');
ok $p2->deactivate;
ok $p2->save;

# Grab from the database again. 20.
ok $p2 = Bric::BC::Person->lookup({id => 1});

# Now grab the new, saved properties. 21-28
ok $p2->get_id;
ok $p2->get_lname;
ok $p2->get_fname;
ok $p2->get_mname;
ok $p2->get_prefix;
ok $p2->get_suffix;
ok !$p2->is_active;
ok $p2->format_name("%p% f% M% l%, s");

# Reactivate the user and reset its values. 29-35.
ok $p2->set_lname('Yoo');
ok $p2->set_fname('Ayeta');
ok $p2->set_mname('Alla');
ok $p2->set_prefix('Mr.');
ok $p2->set_suffix;
ok $p2->activate;
ok $p2->save;

# Get groups and group IDs. 54-56.
ok my @groups = $p2->get_grps;
ok ref $groups[0] eq 'Bric::Util::Grp::Person';
ok @groups = $p2->get_grp_ids;

# Get Person ID 2 and his contacts. 57-66.
ok my $per = Bric::BC::Person->lookup({ id => 2});
ok my (@c) = $per->get_contacts;
ok $c[0]->get_id;
ok $c[0]->get_type;
ok $c[0]->get_value;
ok $c[0]->is_active;
ok $c[1]->get_id;
ok $c[1]->get_type;
ok $c[1]->get_value;
ok $c[1]->is_active;

# Add a contact to ID 2 and fetch again. 67-68.
ok my $c = $per->new_contact('Pager', '(510) 896-9569');
ok $per->save;

# Delete the new contact. 69-71.
ok $per->del_contacts($c->get_id);
ok $per->save;
ok !$c->is_active;

# Grab all Wheeler IDs. 72-73.
ok my $ids = Bric::BC::Person->list_ids({lname => 'Wheeler', fname => 'David'});
ok @$ids;

# Grab all Wheelers. 74-82.
ok my @p3 = Bric::BC::Person->list({lname => 'Wheeler', fname => 'David'});
ok $p3[0]->get_id;
ok $p3[0]->get_lname;
ok $p3[0]->get_fname;
ok $p3[0]->get_mname;
ok $p3[0]->get_prefix;
ok $p3[0]->get_suffix;
ok $p3[0]->is_active;
ok $p3[0]->format_name("%p% f% M% l%, s");

Bric::Util::DBI::prepare(qq{
    DELETE FROM person
    WHERE  id > 1023
})->execute;

Bric::Util::DBI::prepare(qq{
    DELETE FROM contact_value
    WHERE  id > 1023
})->execute;

Bric::Util::DBI::prepare(qq{
    DELETE FROM org
    WHERE  id > 1023
})->execute;


};

if (my $err = $@) {
    print "Error: ", ref $err ? $err->get_msg . ":\n\n" . $err->get_payload
      . "\n" : "$err\n";
}
