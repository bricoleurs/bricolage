package Bric::Biz::Org::Parts::Addr::Test;
use strict;
use warnings;
use base qw(Bric::Test::Base);
use Test::More;

##############################################################################
# Test class loading.
##############################################################################
sub _test_load : Test(1) {
    use_ok('Bric::Biz::Org::Parts::Addr');
}

1;
__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl -w
use Bric::BC::Org;

# Create a new address. Will generally be called from Bric::BC::Org.
my $addr2 =  Bric::BC::Org::Parts::Addr->new({type => 'Shipping',
                         org_id => 7,
                         city => 'Sacramento',
                         state => 'CA',
                         code => '95821',
                         country => 'U.S.A.',
                         lines => '4171 17th Street'
});

print "ID:      ", $addr2->get_id || '', "\n";
print "Saving...\n";
$addr2->save;
$addr2->save; # Make sure it does nothing! (Will need to profile this call.)
print "ID:      ", $addr2->get_id || '', "\n";


print "Changing settings\n";
# Okay, now change everything and save it again.
$addr2->set_city('Carmichael');
$addr2->set_country('US');
$addr2->set_code('95862');
$addr2->set_type('Billing');
$addr2->set_lines('22 Fourth Street', '16th Floor');
$addr2->save;
$addr2->set_lines('4171 17th Street');
$addr2->deactivate;
$addr2->save;

print "Fetching properties:\n";
print "Type:    ", $addr2->get_type || '', "\n";

# Get lines.
foreach my $l ($addr2->get_lines) {
    print "Line:    $l\n";
}

print "City:    ", $addr2->get_city || '', "\n";
print "State:   ", $addr2->get_state || '', "\n";
print "Code:    ", $addr2->get_code || '', "\n";
print "Country: ", $addr2->get_country || '', "\n";
print "Active:  ", $addr2->is_active ? 'Yes' : 'No', "\n";
print "Parts by hashref:\n";
while (my ($k, $v) = each %{ $addr2->get_parts }) {
    print "\t$k: $v\n";
}


# Check out the parts management interface.
print "\nOkay, Let's see what types of parts we've got!\nParts:\n";
print "\t$_\n" for Bric::BC::Org::Parts::Addr->list_parts;
print "\nAdding a part...\n";
Bric::BC::Org::Parts::Addr->add_parts('Province');
print "Fetching parts again...\nParts:\n";
print "\t$_\n" for Bric::BC::Org::Parts::Addr->list_parts;
print "\nDeleting Province, now...\n";
Bric::BC::Org::Parts::Addr->del_parts('Province');
print "Fetching parts again...\nParts:\n";
print "\t$_\n" for Bric::BC::Org::Parts::Addr->list_parts;
print "\n\n";


# Look up an existing record.
print "Looking up an existing record...\n";
my $addr = Bric::BC::Org::Parts::Addr->lookup({id => 1});
print "ID:      ", $addr->get_id || '', "\n";
$addr->set_type('Billing');
print "Type:    ", $addr->get_type || '', "\n";

$addr->set_lines('4171 17th Street', 'line 2', 'line 3');
foreach my $l ($addr->get_lines) {
    print "Line:    $l\n";
}

$addr->set_city('Charlottesville');
print "City:    ", $addr->get_city || '', "\n";
$addr->set_state('VA');
print "State:   ", $addr->get_state || '', "\n";
$addr->set_code('22901');
print "Code:    ", $addr->get_code || '', "\n";
$addr->set_country('US');
print "Country: ", $addr->get_country || '', "\n";
print "Active:  ", $addr->is_active ? 'Yes' : 'No', "\n\n";

$addr->set_part('Vestibule', 'West');
print "Parts:\n";
while (my ($k, $v) = each %{ $addr->get_parts }) {
    print "\t$k: $v\n";
}
print "\n";

# Okay, delete that extra part (it's illegal!).
$addr->set_part('Vestibule', undef);

# Now save it!
$addr->save;




# Test list, now.
print "Fetching several records via list()...\n";
foreach my $addr1 (Bric::BC::Org::Parts::Addr->list({city => 'San Francisco', state => 'CA'})) {
    print "ID:      ", $addr1->get_id || '', "\n";
    print "Type:    ", $addr1->get_type || '', "\n";
    print "City:    ", $addr1->get_city || '', "\n";
    print "Code:    ", $addr1->get_code || '', "\n";
    print "State:   ", $addr1->get_state || '', "\n";
    print "Country: ", $addr1->get_country || '', "\n";
    print "Line:    $_\n" for $addr1->get_lines;
    print "Active:  ", $addr1->is_active ? 'Yes' : 'No', "\n\n";
}


# Test href, now.
print "Fetching several records via href()...\n";
my $href = Bric::BC::Org::Parts::Addr->href({city => 'San Francisco', state => 'CA'});
while (my ($id, $addr4) = each %$href) {
    print "Key ID:  $id\n";
    print "ID:      ", $addr4->get_id || '', "\n";
    print "Type:    ", $addr4->get_type || '', "\n";
    print "City:    ", $addr4->get_city || '', "\n";
    print "Code:    ", $addr4->get_code || '', "\n";
    print "State:   ", $addr4->get_state || '', "\n";
    print "Country: ", $addr4->get_country || '', "\n";
    print "Line:    $_\n" for $addr4->get_lines;
    print "Active:  ", $addr4->is_active ? 'Yes' : 'No', "\n\n";
}

exit unless @ARGV;
# Okay, now delete the bogus rows.
print "Deleting bogus records\n";
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
