package Bric::Biz::Person::User::Test;
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
    use_ok('Bric::Biz::Person::User');
}


__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl -w
use Bric;
use Bric::BC::Person::User;
use Bric::BC::Person;

eval {
# Create a brand new Person:
print "Tesing my_meths().\n";
my @meths = keys %{ Bric::BC::Person::User->my_meths };
print "Meths: @meths\n\n";

print "Creating new User...\n";
my $u1 = Bric::BC::Person::User->new({lname => 'Wheeler',
							 fname => 'David',
							 suffix => 'MA',
							 prefix => 'Mr.',
							 mname => 'Erin',
							 login => rand
});

$u1->set_password('downndirersaeraseraser');
print "Pass:   ", $u1->chk_password('downndirersaeraseraser') || '', "\n";

# Prove we've created it.
print "ID:     ", $u1->get_id || '', "\n";
print "LName:  ", $u1->get_lname || '', "\n";
print "FName:  ", $u1->get_fname || '', "\n";
print "MName:  ", $u1->get_mname || '', "\n";
print "Prefix: ", $u1->get_prefix || '', "\n";
print "Suffix: ", $u1->get_suffix || '', "\n";
print "Login:  ", $u1->get_login || '', "\n";
print "Active: ", $u1->is_active || '', "\n";
print "Name:   ", $u1->format_name("%p% f% M% l%, s"), "\n\n";

# Save it and print the ID again:
print "Saving...\n";
$u1->save;
print "ID:     ", $u1->get_id || '', "\n";


# Grab existing user.
print "Grabbing Existing User ID 1\n";
my $u2 = Bric::BC::Person::User->lookup({id => 1});
# Reset some of its properties.
$u2->set_lname('Whorf');
$u2->set_fname('Benjamin');
$u2->set_mname('Lee');
$u2->set_prefix('Dr.');
$u2->set_suffix('Ph.D');
$u2->deactivate;
$u2->save;

# This should fail:
#eval { $u2->set_id(22) };
if (my $err = $@) {
    print "Error: ", ref $err ? $err->get_msg . ":\n\n" . $err->get_payload
      . "\n" : "$err\n";
}

# Okay, grab him again.
print "Grabbing 1 from the database again.\n";
$u2 = Bric::BC::Person::User->lookup({id => 1});

# Now print them the properties.
print "ID:     ", $u2->get_id || '', "\n";
print "LName:  ", $u2->get_lname || '', "\n";
print "FName:  ", $u2->get_fname || '', "\n";
print "MName:  ", $u2->get_mname || '', "\n";
print "Prefix: ", $u2->get_prefix || '', "\n";
print "Suffix: ", $u2->get_suffix || '', "\n";
print "Active: ", $u2->is_active || '', "\n";
print "Login:  ", $u2->get_login || '', "\n";
print "Name:   ", $u2->format_name("%p% f% M% l%, s"), "\n\n";

# Reactivate the user and reset its values.
$u2->set_lname('Yoo');
$u2->set_fname('Ayeta');
$u2->set_mname('Alla');
$u2->set_prefix('Mr.');
$u2->set_suffix;
$u2->activate;
$u2->save;

print "Getting groups.\n";
print "Group:    ", $_->get_name, "\n" for $u2->get_grps;
print "\n";

print "Getting group IDs.\n";
print "Group ID: ", $_, "\n" for $u2->get_grp_ids;
print "\n";



print "Grabbing all Wheeler IDs\n";
my @ids = Bric::BC::Person::User->list_ids({lname => 'Wheeler', fname => 'David'});
print "IDs: @ids\n";


print "Grabbing all Wheelers!\n";
foreach my $u3 (Bric::BC::Person::User->list({lname => 'Wheeler', fname => 'David'})) {
    print "ID:     ", $u3->get_id || '', "\n";
    print "LName:  ", $u3->get_lname || '', "\n";
    print "FName:  ", $u3->get_fname || '', "\n";
    print "MName:  ", $u3->get_mname || '', "\n";
    print "Prefix: ", $u3->get_prefix || '', "\n";
    print "Suffix: ", $u3->get_suffix || '', "\n";
    print "Login:  ", $u3->get_login || '', "\n";
    print "Active: ", $u3->is_active || '', "\n";
    print "Name:   ", $u3->format_name("%p% f% M% l%, s"), "\n\n";
}

# Okay, now try to create a user from an existing person.
print "Creating new user from existing person\n";
my $p = Bric::BC::Person->lookup({id => 8});
my $u4 = Bric::BC::Person::User->new;
$u4->set_person($p);
$u4->set_password('BricolageRules!');
#$u4->set_login('garth@perijove.com'); # Should fill in automatically.
$u4->save;
print "ID:     ", $u4->get_id || '', "\n";
print "LName:  ", $u4->get_lname || '', "\n";
print "FName:  ", $u4->get_fname || '', "\n";
print "MName:  ", $u4->get_mname || '', "\n";
print "Prefix: ", $u4->get_prefix || '', "\n";
print "Suffix: ", $u4->get_suffix || '', "\n";
print "Login:  ", $u4->get_login || '', "\n";
print "Active: ", $u4->is_active || '', "\n";
print "Pass:   ", $u4->chk_password('BricolageRules!') ? 'Correct' : 'Wrong', "\n";
print "Name:   ", $u4->format_name("%p% f% M% l%, s"), "\n\n";


# Okay, delete the bogus record we created at the top.
print "Deleting bogus records.\n";
Bric::Util::DBI::prepare(qq{
    DELETE FROM usr
    WHERE  id > 1023
})->execute;

Bric::Util::DBI::prepare(qq{
    DELETE FROM org
    WHERE  id > 1023
})->execute;

print "Done!\n";
exit;
};

if (my $err = $@) {
    print "Error: ", ref $err ? $err->get_msg . ":\n\n" . $err->get_payload
      . "\n" : "$err\n";
}
