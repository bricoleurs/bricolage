package Bric::Biz::Org::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Bric::Biz::Org;
use Bric::Util::Grp::Org;
use Test::More;

sub table {'org'}
sub class { 'Bric::Biz::Org' };
sub grp_class { 'Bric::Util::Grp::Org' }
sub new_args {
    ( name      => 'Kineticode',
      long_name => 'Kineticode, Inc.'
    )
}

sub construct {
    my $self = shift;
    my $class = $self->class;
    $class->new({ $self->new_args });
}

sub add_del_obj {
    my ($self, $org) = @_;
    $self->add_del_ids($org->get_id);
}

##############################################################################
# This method is used by setup_orgs to modify the arguments based to the
# constructor based on the number of the org being created. That is,
# setup_orgs creates 5 orgs, each of which will get its constructor arguments
# from this method. Override in subclasses to affect different arguments.
##############################################################################

sub modify_args {
    my ($self, $n) = @_;
    my %args = $self->new_args;
    # Three modified names and 2 modified long_names.
    $args{$n % 2 ? 'name' : 'long_name'} .= $n;
    return \%args;
}

##############################################################################
# Setup methods. These will be run before every test, even if their data might
# not be used for every test.
##############################################################################

sub setup_orgs : Test(setup => 13) {
    my $self = shift;
    # Create a new org group.
    ok( my $grp = $self->grp_class->new({ name => 'Test OrgGrp' }),
        "Create group" );

    my $class = $self->class;

    # Create some test records.
    my @orgs;
    for my $n (1..5) {
        my $args = $self->modify_args($n);
        ok( my $org = $class->new($args), "Create $args->{name}" );
        ok( $org->save, "Save $args->{name}" );
        # Save the ID for deleting.
        $self->add_del_obj($org);
        $grp->add_member({ obj => $org }) if $n % 2;
        push @orgs, $org;
    }

    # Save the group.
    ok( $grp->save, "Save group" );
    ok( my $grp_id = $grp->get_id, "Get group ID" );
    $self->add_del_ids($grp_id, 'grp');
    $self->{test_orgs} = \@orgs;
    $self->{test_grp} = $grp;
}

##############################################################################
# Test constructors.
##############################################################################
# Test the lookup() method.
sub test_lookup : Test(30) {
    my $self = shift;
    my $class = $self->class;
    foreach my $torg (@{ $self->{test_orgs} }) {
        ok( my $oid = $torg->get_id, "Get org ID" );
        ok( my $org = $class->lookup({ id => $oid }), "Look up Org ID $oid" );
        is( $org->get_id, $oid, "Check that the ID is the same" );
        # Check a few attributes.
        is( $org->get_name, $torg->get_name, "Check name" );
        is( $org->get_long_name, $torg->get_long_name, "Check long name" );
        ok( $org->is_active, "Check is active" );
    }
}

##############################################################################
# Test the list() method.
sub test_list : Test(13) {
    my $self = shift;

    my %org = $self->new_args;
    my $class = $self->class;

    # Try name.
    ok( my @orgs = $class->list({ name => $org{name} }),
        "Look up name $org{name}" );
    is( scalar @orgs, 2, "Check for 2 orgs" );

    # Try name + wildcard.
    ok( @orgs = $class->list({ name => "$org{name}%" }),
        "Look up name $org{name}%" );
    is( scalar @orgs, 5, "Check for 5 orgs" );

    # Try long_name.
    ok( @orgs = $class->list({ long_name => $org{long_name} }),
        "Look up long_name $org{long_name}" );
    is( scalar @orgs, 3, "Check for 3 orgs" );

    # Try long_name + wildcard.
    ok( @orgs = $class->list({ long_name => "$org{long_name}%" }),
        "Look up name $org{long_name}%" );
    is( scalar @orgs, 5, "Check for 5 orgs" );

    # Try grp_id.
    my $grp_id = $self->{test_grp}->get_id;
    ok( @orgs = $class->list({ grp_id => $grp_id }),
        "Look up grp_id $grp_id" );
    is( scalar @orgs, 3, "Check for 3 orgs" );

    # Make sure we've got all the Group IDs we think we should have.
    my $all_grp_id = $class->INSTANCE_GROUP_ID;
    foreach my $org (@orgs) {
        my %grp_ids = map { $_ => 1 } $org->get_grp_ids;
        ok( $grp_ids{$all_grp_id} && $grp_ids{$grp_id},
          "Check for both IDs" );
    }
}

##############################################################################
# Test class methods.
##############################################################################
# Test the list_ids() method.
sub test_list_ids : Test(10) {
    my $self = shift;

    my %org = $self->new_args;
    my $class = $self->class;

    # Try name.
    ok( my @org_ids = $class->list({ name => $org{name} }),
        "Look up name $org{name}" );
    is( scalar @org_ids, 2, "Check for 2 orgs" );

    # Try name + wildcard.
    ok( @org_ids = $class->list({ name => "$org{name}%" }),
        "Look up name $org{name}%" );
    is( scalar @org_ids, 5, "Check for 5 orgs" );

    # Try long_name.
    ok( @org_ids = $class->list({ long_name => $org{long_name} }),
        "Look up long_name $org{long_name}" );
    is( scalar @org_ids, 3, "Check for 3 orgs" );

    # Try long_name + wildcard.
    ok( @org_ids = $class->list({ long_name => "$org{long_name}%" }),
        "Look up name $org{long_name}%" );
    is( scalar @org_ids, 5, "Check for 5 orgs" );

    # Try grp_id.
    my $grp_id = $self->{test_grp}->get_id;
    ok( @org_ids = $class->list({ grp_id => $grp_id }),
        "Look up grp_id $grp_id" );
    is( scalar @org_ids, 3, "Check for 3 orgs" );
}

##############################################################################
# Test instance methods.
##############################################################################
# Test save()
sub test_save : Test(4) {
    my $self = shift;
    my $class = $self->class;
    my $org = $self->{test_orgs}[0];
    ok( $org->set_name('foo'), "Change name" );
    ok( $org->save, "Save org" );
    ok( $org = $class->lookup({ id => $org->get_id }),
        "Look up Org" );
    is( $org->get_name, 'foo', "Check name is 'foo'" );
}



1;
__END__
# Here is the original test script for reference. This should be adapted to
# to test addresses and such. Addressees aren't currently used in Bricolage,
# but they likely will be at some point, and we'll want to test the API then.

#!/usr/bin/perl -w
use Bric::Biz::Org;

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
