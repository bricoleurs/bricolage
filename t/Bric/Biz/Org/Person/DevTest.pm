package Bric::Biz::Org::Person::DevTest;
use strict;
use warnings;
use base qw(Bric::Biz::Org::DevTest);
use Bric::Biz::Org::Person;
use Test::More;

sub class { 'Bric::Biz::Org::Person' };
sub new_args {
    my $self = shift;
    my $org = Bric::Biz::Org::DevTest->construct;
    $org->save;
    my $oid = $org->get_id;
    $self->add_del_ids($oid, 'org');
    ( $self->SUPER::new_args,
      person_id  => $self->user_id,
      org_id     => $oid,
      role       => 'Grunt',
      title      => 'Tech Writer',
      department => 'IT'
    )
}

sub add_del_obj {
    my ($self, $org) = @_;
    $self->add_del_ids($org->get_org_id);
}

sub modify_args {
    my ($self, $n) = @_;
    my $args = $self->SUPER::modify_args($n);
    $args->{role} .= $n;
    if ($n % 2) {
        $args->{title} .= $n;
    } else {
        $args->{department} = 'foo';
    }
    return $args;
}

sub test_list : Test(+10) {
    my $self = shift;
    $self->SUPER::test_list(@_);

    my %org = $self->new_args;
    my $class = $self->class;

    # Try role + wildcard.
    ok( my @orgs = $class->list({ role => "$org{role}%" }),
        "Look up role '$org{role}%'" );
    is( scalar @orgs, 5, "Check for 5 orgs" );

    # Try person_id.
    my $uid = $self->user_id;
    ok( @orgs = $class->list({ person_id => $uid }),
        "Look up person_id '$uid'" );
    is( scalar @orgs, 5, "Check for 5 orgs" );

    # Try title.
    ok( @orgs = $class->list({ title => $org{title} }),
        "Look up title '$org{title}'" );
    is( scalar @orgs, 2, "Check for 2 orgs" );

    # Try department.
    ok( @orgs = $class->list({ department => $org{department} }),
        "Look up department '$org{department}'" );
    is( scalar @orgs, 3, "Check for 3 orgs" );

    # Try org_id.
    my $oid = $orgs[0]->get_org_id;
    ok( @orgs = $class->list({ org_id => $oid }),
        "Look up org_id '$oid'" );
    is( scalar @orgs, 1, "Check for 1 org" );
}


1;
__END__
# Here is the original test script for reference. This should be adapted to
# to test addresses and such. Addressees aren't currently used in Bricolage,
# but they likely will be at some point, and we'll want to test the API then.

#!/usr/bin/perl -w

use Bric::BC::Org;
use Bric::BC::Org::Person;
use Bric::BC::Person;

eval {
print "Creating a new Org::Person.\n";
my $o = Bric::BC::Org->lookup({id => 1});
my $p = Bric::BC::Person->lookup({id => 10});
my $porg = $o->add_object($p);
$porg->set_role('Grunt');
$porg->set_title('Tech Writer');
$porg->set_department('Technology Group');

print "ID:      ", $porg->get_id || '', "\n";
$porg->save;
print "ID:      ", $porg->get_id || '', "\n";
print "Name:    ", $porg->get_name || '', "\n";
print "LName:   ", $porg->get_long_name || '', "\n";
print "PID:     ", $porg->get_person_id || '', "\n";
print "OID:     ", $porg->get_org_id || '', "\n";
print "Role:    ", $porg->get_role || '', "\n";
print "Title:   ", $porg->get_title || '', "\n";
print "Dept:    ", $porg->get_department || '', "\n";
print "Pesonal: ", $porg->is_personal ? 'Yes' : 'No', "\n";
print "Active:  ", $porg->is_active ? 'Yes' : 'No', "\n\n";

print "Deactivating...\n";
$porg->deactivate;
$porg->save;
print "Active:  ", $porg->is_active ? 'Yes' : 'No', "\n";
$o = Bric::BC::Org->lookup({id => 1});
print "Org should still be active.\n";
print "Org Active: ", $o->is_active ? 'Yes' : 'No', "\n\n";


print "Fetching an existing Org::Person.\n";
my $porg2 = Bric::BC::Org::Person->lookup({id => 1});
print "ID:      ", $porg2->get_id || '', "\n";
print "Name:    ", $porg2->get_name || '', "\n";
print "LName:   ", $porg2->get_long_name || '', "\n";
print "PID:     ", $porg2->get_person_id || '', "\n";
print "OID:     ", $porg2->get_org_id || '', "\n";
print "Role:    ", $porg2->get_role || '', "\n";
print "Title:   ", $porg2->get_title || '', "\n";
print "Dept:    ", $porg2->get_department || '', "\n";
print "Pesonal: ", $porg2->is_personal ? 'Yes' : 'No', "\n";
print "Active:  ", $porg2->is_active ? 'Yes' : 'No', "\n\n";


print "Fetching addresses for Existing Org::Person.\n";
foreach my $addr ($porg2->get_addr) {
    print "ID: ", $addr->get_id, "\n";
    print "Type: ", $addr->get_type, "\n";
    map { print "$_\n" } $addr->get_lines;
    print $addr->get_city || '', ", ", $addr->get_state || '', "\n";
    print $addr->get_code || '', "  ", $addr->get_country || '', "\n\n";
}

print "Deleting an address.\n";
$porg2->del_addr(2);
$porg2->save;
$porg2 = Bric::BC::Org::Person->lookup({id => 1});
print "Fetching addresses again.\n";
foreach my $addr ($porg2->get_addr) {
    print "ID: ", $addr->get_id, "\n";
    print "Type: ", $addr->get_type, "\n";
    map { print "$_\n" } $addr->get_lines;
    print $addr->get_city || '', ", ", $addr->get_state || '', "\n";
    print $addr->get_code || '', "  ", $addr->get_country || '', "\n\n";
}

print "Adding an address.\n";
$porg2->add_addr($o->get_addr(2));
$porg2->save;
$porg2 = Bric::BC::Org::Person->lookup({id => 1});
print "Fetching addresses again.\n";
foreach my $addr ($porg2->get_addr) {
    print "ID: ", $addr->get_id, "\n";
    print "Type: ", $addr->get_type, "\n";
    map { print "$_\n" } $addr->get_lines;
    print $addr->get_city || '', ", ", $addr->get_state || '', "\n";
    print $addr->get_code || '', "  ", $addr->get_country || '', "\n\n";
}

print "Creating a new address.\n";
my $addr = $porg2->new_addr;
$addr->set_type('Temp');
$addr->set_lines('483 18th Street', 'Suite 24');
$addr->set_city('East Lansing');
$addr->set_state('MI');
$addr->set_code('59685');
$addr->set_country('Canada');
$porg2->save;
$porg2 = Bric::BC::Org::Person->lookup({id => 1});
print "Fetching addresses again.\n";
foreach my $addr ($porg2->get_addr) {
    print "ID: ", $addr->get_id, "\n";
    print "Type: ", $addr->get_type, "\n";
    map { print "$_\n" } $addr->get_lines;
    print $addr->get_city || '', ", ", $addr->get_state || '', "\n";
    print $addr->get_code || '', "  ", $addr->get_country || '', "\n\n";
}

print "Fetching existing Org::Persons working for About.\n";
foreach my $po (Bric::BC::Org::Person->list({name => 'About'})) {
    print "ID:      ", $po->get_id || '', "\n";
    print "Name:    ", $po->get_name || '', "\n";
    print "LName:   ", $po->get_long_name || '', "\n";
    print "PID:     ", $po->get_person_id || '', "\n";
    print "OID:     ", $po->get_org_id || '', "\n";
    print "Role:    ", $po->get_role || '', "\n";
    print "Title:   ", $po->get_title || '', "\n";
    print "Dept:    ", $po->get_department || '', "\n";
    print "Pesonal: ", $po->is_personal ? 'Yes' : 'No', "\n";
    print "Active:  ", $po->is_active ? 'Yes' : 'No', "\n\n";
}

print "Fetching existing Org::Persons with a role of 'Employee'.\n";
foreach my $po (Bric::BC::Org::Person->list({role => 'Employee'})) {
    print "ID:      ", $po->get_id || '', "\n";
    print "Name:    ", $po->get_name || '', "\n";
    print "LName:   ", $po->get_long_name || '', "\n";
    print "PID:     ", $po->get_person_id || '', "\n";
    print "OID:     ", $po->get_org_id || '', "\n";
    print "Role:    ", $po->get_role || '', "\n";
    print "Title:   ", $po->get_title || '', "\n";
    print "Dept:    ", $po->get_department || '', "\n";
    print "Pesonal: ", $po->is_personal ? 'Yes' : 'No', "\n";
    print "Active:  ", $po->is_active ? 'Yes' : 'No', "\n\n";
}


# Okay, delete the bogus record we created at the top.
print "Deleting bogus records.\n";
Bric::Util::DBI::prepare(qq{
    DELETE FROM person_org
    WHERE  id > 1023
})->execute;
Bric::Util::DBI::prepare(qq{
    DELETE FROM addr_part
    WHERE  id > 1023
})->execute;

Bric::Util::DBI::prepare(qq{
    DELETE FROM addr
    WHERE  id > 1023
})->execute;
print "Done!\n";

};

if (my $err = $@) {
    print "Error: ", ref $err ? $err->get_msg . ":\n\n" . $err->get_payload
      . "\n" : "$err\n";
}
