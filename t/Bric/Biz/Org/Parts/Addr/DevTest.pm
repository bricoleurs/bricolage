package Bric::Biz::Org::Parts::Addr::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Biz::Org;
use Bric::Biz::Org::Parts::Addr;
use Bric::Util::DBI qw(:junction);

my %addr = (
    type    => 'Shipping',
    city    => 'Sacramento',
    state   => 'CA',
    code    => '95821',
    country => 'U.S.A.',
    lines   => ['4171 17th Street'],
);

sub table { 'addr' };

sub org {
    my $self = shift;
    my $org = Bric::Biz::Org->new({
        name      => 'Kineticode',
        long_name => 'Kineticode, Inc.'
    })->save;
    $self->add_del_ids($org->get_id, 'org');
    return $org;
}

sub person {
    my $self = shift;
    my $person = Bric::Biz::Person->new({
        lname => 'Wheeler',
        fname => 'David',
    })->save;
    $self->add_del_ids($person->get_id, 'person');
    return $person;
}

##############################################################################
# Test constructors.
##############################################################################
# Test new().
sub test_const : Test(22) {
    my $self = shift;

    ok my $org = $self->org, "Create a new org object";
    $addr{org_id} = $org->get_id;

    ok my $addr = Bric::Biz::Org::Parts::Addr->new,
        "Create empty address";
    isa_ok($addr, 'Bric::Biz::Org::Parts::Addr');
    isa_ok($addr, 'Bric');

    ok $addr = Bric::Biz::Org::Parts::Addr->new({%addr}), "Create a new addr";

    # Check the attributes.
    is_deeply scalar $addr->get_lines, $addr{lines}, "Check lines";
    for my $attr (grep { $_ ne 'lines' } keys %addr) {
        my $meth = "get_$attr";
        is $addr->$meth, $addr{$attr}, "Check $attr";
    }

    # Save it.
    ok $addr->save, "Save the new addr";
    my $cid = $addr->get_id;
    $self->add_del_ids($cid);

    # Now look it up.
    ok $addr = Bric::Biz::Org::Parts::Addr->lookup({ id => $cid }),
      "Look it up again";
    is $addr->get_id, $cid, "It should have the same ID";

    # Check the attributes again.
    is_deeply scalar $addr->get_lines, $addr{lines}, "Check lines";
    for my $attr (grep { $_ ne 'lines' } keys %addr) {
        my $meth = "get_$attr";
        is $addr->$meth, $addr{$attr}, "Check $attr";
    }
}

##############################################################################
# Test the list() method.
sub test_list : Test(65) {
    my $self = shift;

    # My god this is hideous. What was I thinking? Oh yeah, I remember. It
    # was, "I haven't a clue what I'm doing!"
    ok my $person = $self->person, 'Construct a person object';
    ok my $person2 = $self->person, 'Construct another person object';
    ok my $porg = ($person->get_orgs)[0], 'Get the personal org';
    ok my $porg2 = ($person2->get_orgs)[0], 'Get the second personal org';
    ok my $org = Bric::Biz::Org->lookup({ id => $porg->get_org_id }),
      'Look up the first org';
    ok my $org2 = Bric::Biz::Org->lookup({ id => $porg2->get_org_id }),
      'Look up the second org';

    # Create some test records.
    for my $n (1..5) {
        my %args = %addr;
        $args{type} .= $n;
        $args{city} = 'San Francisco' if $n % 2;
        $args{state} = 'OR' unless $n % 2;
        ($args{code} = $addr{code}) =~ s/21/14/ unless $n % 2;
        ($args{country} = $addr{country}) =~ s/\.//g if $n %2;
        my $aorg = $n % 2 ? $org : $org2;
        ok( my $addr = $aorg->new_addr(\%args),
            "Create $args{type}" );
        ok( $addr->save, "Save the address" );
        # Save the ID for deleting.
        $self->add_del_ids([$addr->get_id]);
    }
    ok $org->save, "Save the org object";
    ok $org2->save, "Save the other org object";

    # Try type.
    ok my @addrs = Bric::Biz::Org::Parts::Addr->list({
        type => "$addr{type}1"
    }), "Look up by type";
    is scalar @addrs, 1, "Should have one address";
    ok @addrs = Bric::Biz::Org::Parts::Addr->list({ type => "$addr{type}%" }),
      "Look up by type '$addr{type}%";
    is scalar @addrs, 5, "Should have five addresses";
    isa_ok $_, 'Bric::Biz::Org::Parts::Addr' for @addrs;
    ok @addrs = Bric::Biz::Org::Parts::Addr->list({
        type => ANY("$addr{type}1", "$addr{type}2"),
    }), "Look up by ANY(type)";
    is scalar @addrs, 2, "Should have two addresses";

    # Try city.
    ok @addrs = Bric::Biz::Org::Parts::Addr->list({
        city => 'Sacramento',
    }), 'Look up by city';
    is scalar @addrs, 2, 'Should have two addresses';
    ok @addrs = Bric::Biz::Org::Parts::Addr->list({ city => 'Sa%' }),
      'Look up by city "Sa%"';
    is scalar @addrs, 5, 'Should have five addresses';
    ok @addrs = Bric::Biz::Org::Parts::Addr->list({
        city => ANY('Sacramento', 'San Francisco')
    }), 'Look up by ANY(city)';
    is scalar @addrs, 5, 'Should have five addresses';

    # Try state.
    ok @addrs = Bric::Biz::Org::Parts::Addr->list({
        state => 'CA',
    }), 'Look up by state';
    is scalar @addrs, 3, 'Should have three addresses';
    ok @addrs = Bric::Biz::Org::Parts::Addr->list({ state => '%' }),
      'Look up by state "%"';
    is scalar @addrs, 5, 'Should have five addresses';
    ok @addrs = Bric::Biz::Org::Parts::Addr->list({
        state => ANY('OR', 'CA')
    }), 'Look up by ANY(state)';
    is scalar @addrs, 5, 'Should have five addresses';

    # Try code.
    ok @addrs = Bric::Biz::Org::Parts::Addr->list({
        code => '95821',
    }), 'Look up by code';
    is scalar @addrs, 3, 'Should have three addresses';
    ok @addrs = Bric::Biz::Org::Parts::Addr->list({ code => '958%' }),
      'Look up by code "%"';
    is scalar @addrs, 5, 'Should have five addresses';
    ok @addrs = Bric::Biz::Org::Parts::Addr->list({
        code => ANY('95814', '95821')
    }), 'Look up by ANY(code)';
    is scalar @addrs, 5, 'Should have five addresses';

    # Try country.
    ok @addrs = Bric::Biz::Org::Parts::Addr->list({
        country => 'U.S.A.',
    }), 'Look up by country';
    is scalar @addrs, 2, 'Should have two addresses';
    ok @addrs = Bric::Biz::Org::Parts::Addr->list({ country => 'U%' }),
      'Look up by country "U%"';
    is scalar @addrs, 5, 'Should have five addresses';
    ok @addrs = Bric::Biz::Org::Parts::Addr->list({
        country => ANY('U.S.A.', 'USA')
    }), 'Look up by ANY(country)';
    is scalar @addrs, 5, 'Should have five addresses';

    # Try org_id.
    ok @addrs = Bric::Biz::Org::Parts::Addr->list({
        org_id => $org->get_id,
    }), 'Look up by org_id';
    is scalar @addrs, 3, 'Should have three addresses';
    ok @addrs = Bric::Biz::Org::Parts::Addr->list({
        org_id => ANY($org->get_id, $org2->get_id)
    }), 'Look up by ANY(org_id)';
    is scalar @addrs, 5, 'Should have five addresses';

    # Try person_id.
    ok @addrs = Bric::Biz::Org::Parts::Addr->list({
        person_id => $person->get_id,
    }), 'Look up by person_id';
    is scalar @addrs, 3, 'Should have three addresses';
    ok @addrs = Bric::Biz::Org::Parts::Addr->list({
        person_id => ANY($person->get_id, $person2->get_id)
    }), 'Look up by ANY(person_id)';
    is scalar @addrs, 5, 'Should have five addresses';

    return "Test person org ID later, or dump this horrible API!";
    # XXX It's just too bloody much work to get this to work. No point in
    # wasting any more time right now, since currently no one uses addresses.
    # Will need to refactor the above code to use the porg objects and their
    # address collections to get this to work properly.

    # Try po_id.
    ok @addrs = Bric::Biz::Org::Parts::Addr->list({
        po_id => $porg->get_id,
    }), 'Look up by po_id';
    is scalar @addrs, 3, 'Should have three addresses';
    ok @addrs = Bric::Biz::Org::Parts::Addr->list({
        po_id => ANY($porg->get_id, $porg2->get_id)
    }), 'Look up by ANY(po_id)';
    is scalar @addrs, 5, 'Should have five addresses';

}

##############################################################################
# Test the list_ids() method.
sub test_list_ids : Test(65) {
    my $self = shift;

    # My god this is hideous. What was I thinking? Oh yeah, I remember. It
    # was, "I haven't a clue what I'm doing!"
    ok my $person = $self->person, 'Construct a person object';
    ok my $person2 = $self->person, 'Construct another person object';
    ok my $porg = ($person->get_orgs)[0], 'Get the personal org';
    ok my $porg2 = ($person2->get_orgs)[0], 'Get the second personal org';
    ok my $org = Bric::Biz::Org->lookup({ id => $porg->get_org_id }),
      'Look up the first org';
    ok my $org2 = Bric::Biz::Org->lookup({ id => $porg2->get_org_id }),
      'Look up the second org';

    # Create some test records.
    for my $n (1..5) {
        my %args = %addr;
        $args{type} .= $n;
        $args{city} = 'San Francisco' if $n % 2;
        $args{state} = 'OR' unless $n % 2;
        ($args{code} = $addr{code}) =~ s/21/14/ unless $n % 2;
        ($args{country} = $addr{country}) =~ s/\.//g if $n %2;
        my $aorg = $n % 2 ? $org : $org2;
        ok( my $addr = $aorg->new_addr(\%args),
            "Create $args{type}" );
        ok( $addr->save, "Save the address" );
        # Save the ID for deleting.
        $self->add_del_ids([$addr->get_id]);
    }
    ok $org->save, "Save the org object";
    ok $org2->save, "Save the other org object";

    # Try type.
    ok my @addr_ids = Bric::Biz::Org::Parts::Addr->list_ids({
        type => "$addr{type}1"
    }), "Look up by type";
    is scalar @addr_ids, 1, "Should have one address";
    ok @addr_ids = Bric::Biz::Org::Parts::Addr->list_ids({ type => "$addr{type}%" }),
      "Look up by type '$addr{type}%";
    is scalar @addr_ids, 5, "Should have five address IDs";
    like $_, qr/^\d+$/, "$_ Should be an ID" for @addr_ids;
    ok @addr_ids = Bric::Biz::Org::Parts::Addr->list_ids({
        type => ANY("$addr{type}1", "$addr{type}2"),
    }), "Look up by ANY(type)";
    is scalar @addr_ids, 2, "Should have two address IDs";

    # Try city.
    ok @addr_ids = Bric::Biz::Org::Parts::Addr->list_ids({
        city => 'Sacramento',
    }), 'Look up by city';
    is scalar @addr_ids, 2, 'Should have two address IDs';
    ok @addr_ids = Bric::Biz::Org::Parts::Addr->list_ids({ city => 'Sa%' }),
      'Look up by city "Sa%"';
    is scalar @addr_ids, 5, 'Should have five address IDs';
    ok @addr_ids = Bric::Biz::Org::Parts::Addr->list_ids({
        city => ANY('Sacramento', 'San Francisco')
    }), 'Look up by ANY(city)';
    is scalar @addr_ids, 5, 'Should have five address IDs';

    # Try state.
    ok @addr_ids = Bric::Biz::Org::Parts::Addr->list_ids({
        state => 'CA',
    }), 'Look up by state';
    is scalar @addr_ids, 3, 'Should have three address IDs';
    ok @addr_ids = Bric::Biz::Org::Parts::Addr->list_ids({ state => '%' }),
      'Look up by state "%"';
    is scalar @addr_ids, 5, 'Should have five address IDs';
    ok @addr_ids = Bric::Biz::Org::Parts::Addr->list_ids({
        state => ANY('OR', 'CA')
    }), 'Look up by ANY(state)';
    is scalar @addr_ids, 5, 'Should have five address IDs';

    # Try code.
    ok @addr_ids = Bric::Biz::Org::Parts::Addr->list_ids({
        code => '95821',
    }), 'Look up by code';
    is scalar @addr_ids, 3, 'Should have three address IDs';
    ok @addr_ids = Bric::Biz::Org::Parts::Addr->list_ids({ code => '958%' }),
      'Look up by code "%"';
    is scalar @addr_ids, 5, 'Should have five address IDs';
    ok @addr_ids = Bric::Biz::Org::Parts::Addr->list_ids({
        code => ANY('95814', '95821')
    }), 'Look up by ANY(code)';
    is scalar @addr_ids, 5, 'Should have five address IDs';

    # Try country.
    ok @addr_ids = Bric::Biz::Org::Parts::Addr->list_ids({
        country => 'U.S.A.',
    }), 'Look up by country';
    is scalar @addr_ids, 2, 'Should have two address IDs';
    ok @addr_ids = Bric::Biz::Org::Parts::Addr->list_ids({ country => 'U%' }),
      'Look up by country "U%"';
    is scalar @addr_ids, 5, 'Should have five address IDs';
    ok @addr_ids = Bric::Biz::Org::Parts::Addr->list_ids({
        country => ANY('U.S.A.', 'USA')
    }), 'Look up by ANY(country)';
    is scalar @addr_ids, 5, 'Should have five address IDs';

    # Try org_id.
    ok @addr_ids = Bric::Biz::Org::Parts::Addr->list_ids({
        org_id => $org->get_id,
    }), 'Look up by org_id';
    is scalar @addr_ids, 3, 'Should have three address IDs';
    ok @addr_ids = Bric::Biz::Org::Parts::Addr->list_ids({
        org_id => ANY($org->get_id, $org2->get_id)
    }), 'Look up by ANY(org_id)';
    is scalar @addr_ids, 5, 'Should have five address IDs';

    # Try person_id.
    ok @addr_ids = Bric::Biz::Org::Parts::Addr->list_ids({
        person_id => $person->get_id,
    }), 'Look up by person_id';
    is scalar @addr_ids, 3, 'Should have three address IDs';
    ok @addr_ids = Bric::Biz::Org::Parts::Addr->list_ids({
        person_id => ANY($person->get_id, $person2->get_id)
    }), 'Look up by ANY(person_id)';
    is scalar @addr_ids, 5, 'Should have five address IDs';

    return "Test person org ID later, or dump this horrible API!";
    # XXX It's just too bloody much work to get this to work. No point in
    # wasting any more time right now, since currently no one uses addresses.
    # Will need to refactor the above code to use the porg objects and their
    # address collections to get this to work properly.

    # Try po_id.
    ok @addr_ids = Bric::Biz::Org::Parts::Addr->list_ids({
        po_id => $porg->get_id,
    }), 'Look up by po_id';
    is scalar @addr_ids, 3, 'Should have three address IDs';
    ok @addr_ids = Bric::Biz::Org::Parts::Addr->list_ids({
        po_id => ANY($porg->get_id, $porg2->get_id)
    }), 'Look up by ANY(po_id)';
    is scalar @addr_ids, 5, 'Should have five address IDs';

}

##############################################################################
# Test the href() method.
sub test_href : Test(70) {
    my $self = shift;

    # My god this is hideous. What was I thinking? Oh yeah, I remember. It
    # was, "I haven't a clue what I'm doing!"
    ok my $person = $self->person, 'Construct a person object';
    ok my $person2 = $self->person, 'Construct another person object';
    ok my $porg = ($person->get_orgs)[0], 'Get the personal org';
    ok my $porg2 = ($person2->get_orgs)[0], 'Get the second personal org';
    ok my $org = Bric::Biz::Org->lookup({ id => $porg->get_org_id }),
      'Look up the first org';
    ok my $org2 = Bric::Biz::Org->lookup({ id => $porg2->get_org_id }),
      'Look up the second org';

    # Create some test records.
    for my $n (1..5) {
        my %args = %addr;
        $args{type} .= $n;
        $args{city} = 'San Francisco' if $n % 2;
        $args{state} = 'OR' unless $n % 2;
        ($args{code} = $addr{code}) =~ s/21/14/ unless $n % 2;
        ($args{country} = $addr{country}) =~ s/\.//g if $n %2;
        my $aorg = $n % 2 ? $org : $org2;
        ok( my $addr = $aorg->new_addr(\%args),
            "Create $args{type}" );
        ok( $addr->save, "Save the address" );
        # Save the ID for deleting.
        $self->add_del_ids([$addr->get_id]);
    }
    ok $org->save, "Save the org object";
    ok $org2->save, "Save the other org object";

    # Try type.
    ok my $addrs = Bric::Biz::Org::Parts::Addr->href({
        type => "$addr{type}1"
    }), "Look up by type";
    is scalar keys %$addrs, 1, "Should have one address";
    ok $addrs = Bric::Biz::Org::Parts::Addr->href({ type => "$addr{type}%" }),
      "Look up by type '$addr{type}%";
    is scalar keys %$addrs, 5, "Should have five addresses";
    isa_ok $_, 'Bric::Biz::Org::Parts::Addr' for values %$addrs;
    is $_, $addrs->{$_}->get_id, "Should be indexed by ID"
      for keys %$addrs;
    ok $addrs = Bric::Biz::Org::Parts::Addr->href({
        type => ANY("$addr{type}1", "$addr{type}2"),
    }), "Look up by ANY(type)";
    is scalar keys %$addrs, 2, "Should have two addresses";

    # Try city.
    ok $addrs = Bric::Biz::Org::Parts::Addr->href({
        city => 'Sacramento',
    }), 'Look up by city';
    is scalar keys %$addrs, 2, 'Should have two addresses';
    ok $addrs = Bric::Biz::Org::Parts::Addr->href({ city => 'Sa%' }),
      'Look up by city "Sa%"';
    is scalar keys %$addrs, 5, 'Should have five addresses';
    ok $addrs = Bric::Biz::Org::Parts::Addr->href({
        city => ANY('Sacramento', 'San Francisco')
    }), 'Look up by ANY(city)';
    is scalar keys %$addrs, 5, 'Should have five addresses';

    # Try state.
    ok $addrs = Bric::Biz::Org::Parts::Addr->href({
        state => 'CA',
    }), 'Look up by state';
    is scalar keys %$addrs, 3, 'Should have three addresses';
    ok $addrs = Bric::Biz::Org::Parts::Addr->href({ state => '%' }),
      'Look up by state "%"';
    is scalar keys %$addrs, 5, 'Should have five addresses';
    ok $addrs = Bric::Biz::Org::Parts::Addr->href({
        state => ANY('OR', 'CA')
    }), 'Look up by ANY(state)';
    is scalar keys %$addrs, 5, 'Should have five addresses';

    # Try code.
    ok $addrs = Bric::Biz::Org::Parts::Addr->href({
        code => '95821',
    }), 'Look up by code';
    is scalar keys %$addrs, 3, 'Should have three addresses';
    ok $addrs = Bric::Biz::Org::Parts::Addr->href({ code => '958%' }),
      'Look up by code "%"';
    is scalar keys %$addrs, 5, 'Should have five addresses';
    ok $addrs = Bric::Biz::Org::Parts::Addr->href({
        code => ANY('95814', '95821')
    }), 'Look up by ANY(code)';
    is scalar keys %$addrs, 5, 'Should have five addresses';

    # Try country.
    ok $addrs = Bric::Biz::Org::Parts::Addr->href({
        country => 'U.S.A.',
    }), 'Look up by country';
    is scalar keys %$addrs, 2, 'Should have two addresses';
    ok $addrs = Bric::Biz::Org::Parts::Addr->href({ country => 'U%' }),
      'Look up by country "U%"';
    is scalar keys %$addrs, 5, 'Should have five addresses';
    ok $addrs = Bric::Biz::Org::Parts::Addr->href({
        country => ANY('U.S.A.', 'USA')
    }), 'Look up by ANY(country)';
    is scalar keys %$addrs, 5, 'Should have five addresses';

    # Try org_id.
    ok $addrs = Bric::Biz::Org::Parts::Addr->href({
        org_id => $org->get_id,
    }), 'Look up by org_id';
    is scalar keys %$addrs, 3, 'Should have three addresses';
    ok $addrs = Bric::Biz::Org::Parts::Addr->href({
        org_id => ANY($org->get_id, $org2->get_id)
    }), 'Look up by ANY(org_id)';
    is scalar keys %$addrs, 5, 'Should have five addresses';

    # Try person_id.
    ok $addrs = Bric::Biz::Org::Parts::Addr->href({
        person_id => $person->get_id,
    }), 'Look up by person_id';
    is scalar keys %$addrs, 3, 'Should have three addresses';
    ok $addrs = Bric::Biz::Org::Parts::Addr->href({
        person_id => ANY($person->get_id, $person2->get_id)
    }), 'Look up by ANY(person_id)';
    is scalar keys %$addrs, 5, 'Should have five addresses';

    return "Test person org ID later, or dump this horrible API!";
    # XXX It's just too bloody much work to get this to work. No point in
    # wasting any more time right now, since currently no one uses addresses.
    # Will need to refactor the above code to use the porg objects and their
    # address collections to get this to work properly.

    # Try po_id.
    ok $addrs = Bric::Biz::Org::Parts::Addr->href({
        po_id => $porg->get_id,
    }), 'Look up by po_id';
    is scalar keys %$addrs, 3, 'Should have three addresses';
    ok $addrs = Bric::Biz::Org::Parts::Addr->href({
        po_id => ANY($porg->get_id, $porg2->get_id)
    }), 'Look up by ANY(po_id)';
    is scalar keys %$addrs, 5, 'Should have five addresses';

}

1;
__END__
