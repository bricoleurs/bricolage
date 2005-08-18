package Bric::Biz::Contact::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Biz::Contact;
use Bric::Biz::Person;
use Bric::Util::DBI qw(:junction);

my %contact = (
    type        => 'Primary Email',
    value       => 'david@kineticode.com',
);

sub table { 'contact_value' };

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
sub test_const : Test(11) {
    my $self = shift;

    ok( my $contact = Bric::Biz::Contact->new,
        "Create empty contact type" );
    isa_ok($contact, 'Bric::Biz::Contact');
    isa_ok($contact, 'Bric');

    ok( $contact = Bric::Biz::Contact->new({%contact}),
        "Create a new contact");

    # Check the attributes.
    for my $attr (keys %contact) {
        my $meth = "get_$attr";
        is $contact->$meth, $contact{$attr}, "Check $attr";
    }

    # Save it.
    ok $contact->save, "Save the new contact";
    my $cid = $contact->get_id;
    $self->add_del_ids($cid);

    # Now look it up.
    ok $contact = Bric::Biz::Contact->lookup({ id => $cid }),
      "Look it up again";
    is $contact->get_id, $cid, "It should have the same ID";

    # Check the attributes again.
    for my $attr (keys %contact) {
        my $meth = "get_$attr";
        is $contact->$meth, $contact{$attr}, "Check $attr";
    }

}

##############################################################################
# Test the list() method.
sub test_list : Test(47) {
    my $self = shift;
    ok my $person = $self->person, "Construct a person object";
    ok my $person2 = $self->person, "Construct another person object";

    # Create some test records.
    for my $n (1..5) {
        my %args = %contact;
        # Make sure the name is unique.
        $args{value} = 'ovid@kineticode.com' if $n % 2;
        $args{type}  = 'Secondary Email' if $n % 2;
        ok( my $contact = Bric::Biz::Contact->new(\%args),
            "Create $args{value}" );
        ok( $contact->save, "Save $args{value}" );
        # Save the ID for deleting.
        $self->add_del_ids([$contact->get_id]);
        $person->add_new_contacts($contact) unless $n % 2;
        $person2->add_new_contacts($contact) if $n % 2;
    }
    ok $person->save, "Save the person object";
    ok $person2->save, "Save the other person object";

    # Try type.
    ok my @contacts = Bric::Biz::Contact->list({ type => 'Primary Email' }),
      "Look up by type";
    is scalar @contacts, 2, "Should have two contacts";
    ok @contacts = Bric::Biz::Contact->list({ type => '%Email%' }),
      "Look up by type '%Email%";
    is scalar @contacts, 5, "Should have five contacts";
    ok @contacts = Bric::Biz::Contact->list({
        type => ANY('Primary Email', 'Secondary Email'),
    }), "Look up by ANY(type)";
    is scalar @contacts, 5, "Should have five contacts";
    isa_ok $_, 'Bric::Biz::Contact' for @contacts;

    # Try ID.
    my @ids = map { $_->get_id } @contacts;
    ok @contacts = Bric::Biz::Contact->list({ id => $ids[0] }),
      "Look up by id";
    is scalar @contacts, 1, "Should have one contact";
    ok @contacts = Bric::Biz::Contact->list({ id => ANY(@ids) }),
      "Look up by ANY(id)";
    is scalar @contacts, 5, "Should have five contacts";

    # Try value.
    ok @contacts = Bric::Biz::Contact->list({
        value => 'david@kineticode.com' }), "Look up by value";
    is scalar @contacts, 2, "Should have two contacts";
    ok @contacts = Bric::Biz::Contact->list({ value => '%@kineticode.com' }),
      "Look up by value '%\@kineticode.com";
    is scalar @contacts, 5, "Should have five contacts";
    ok @contacts = Bric::Biz::Contact->list({
        value => ANY('david@kineticode.com', 'ovid@kineticode.com'),
    }), "Look up by ANY(value)";
    is scalar @contacts, 5, "Should have five contacts";

    # Try person_id.
    ok @contacts = Bric::Biz::Contact->list({ person_id => $person->get_id }),
      "Look up by person_id";
    is scalar @contacts, 2, "Should have two contacts";
    ok @contacts = Bric::Biz::Contact->list({
        person_id => ANY($person->get_id, $person2->get_id) }),
      "Look up by ANY(person_id)";
    is scalar @contacts, 5, "Should have five contacts";

    # Try alertable.
    ok @contacts = Bric::Biz::Contact->list({ alertable => 1 }),
      "Look up by alertable";
    is scalar @contacts, 5, "Should have five contacts";

    # Try description.
    ok @contacts = Bric::Biz::Contact->list({
        description => 'Primary Electronic Mail Address'
    }), "Look up by description";
    is scalar @contacts, 2, "Should have two contacts";
    ok @contacts = Bric::Biz::Contact->list({ description => '%mail%' }),
      "Look up by description '%mail%";
    is scalar @contacts, 5, "Should have five contacts";
    ok @contacts = Bric::Biz::Contact->list({
        description => ANY(
            'Primary Electronic Mail Address',
            'Secondary Electronic Mail Address',
        ),
    }), "Look up by ANY(description)";
    is scalar @contacts, 5, "Should have five contacts";
}

##############################################################################
# Test the href() method.
sub test_href : Test(52) {
    my $self = shift;
    ok my $person = $self->person, "Construct a person object";
    ok my $person2 = $self->person, "Construct another person object";

    # Create some test records.
    for my $n (1..5) {
        my %args = %contact;
        # Make sure the name is unique.
        $args{value} = 'ovid@kineticode.com' if $n % 2;
        $args{type}  = 'Secondary Email' if $n % 2;
        ok( my $contact = Bric::Biz::Contact->new(\%args),
            "Create $args{value}" );
        ok( $contact->save, "Save $args{value}" );
        # Save the ID for deleting.
        $self->add_del_ids([$contact->get_id]);
        $person->add_new_contacts($contact) unless $n % 2;
        $person2->add_new_contacts($contact) if $n % 2;
    }
    ok $person->save, "Save the person object";
    ok $person2->save, "Save the other person object";

    # Try type.
    ok my $contacts = Bric::Biz::Contact->href({ type => 'Primary Email' }),
      "Look up by type";
    is scalar keys %$contacts, 2, "Should have two contacts";
    ok $contacts = Bric::Biz::Contact->href({ type => '%Email%' }),
      "Look up by type '%Email%";
    is scalar keys %$contacts, 5, "Should have five contacts";
    ok $contacts = Bric::Biz::Contact->href({
        type => ANY('Primary Email', 'Secondary Email'),
    }), "Look up by ANY(type)";
    is scalar keys %$contacts, 5, "Should have five contacts";
    isa_ok $_, 'Bric::Biz::Contact' for values %$contacts;
    is $_, $contacts->{$_}->get_id, "Should be indexed by ID"
      for keys %$contacts;

    # Try ID.
    my @ids = map { $_->get_id } values %$contacts;
    ok $contacts = Bric::Biz::Contact->href({ id => $ids[0] }),
      "Look up by id";
    is scalar keys %$contacts, 1, "Should have one contact";
    ok $contacts = Bric::Biz::Contact->href({ id => ANY(@ids) }),
      "Look up by ANY(id)";
    is scalar keys %$contacts, 5, "Should have five contacts";

    # Try value.
    ok $contacts = Bric::Biz::Contact->href({
        value => 'david@kineticode.com' }), "Look up by value";
    is scalar keys %$contacts, 2, "Should have two contacts";
    ok $contacts = Bric::Biz::Contact->href({ value => '%@kineticode.com' }),
      "Look up by value '%\@kineticode.com";
    is scalar keys %$contacts, 5, "Should have five contacts";
    ok $contacts = Bric::Biz::Contact->href({
        value => ANY('david@kineticode.com', 'ovid@kineticode.com'),
    }), "Look up by ANY(value)";
    is scalar keys %$contacts, 5, "Should have five contacts";

    # Try person_id.
    ok $contacts = Bric::Biz::Contact->href({ person_id => $person->get_id }),
      "Look up by person_id";
    is scalar keys %$contacts, 2, "Should have two contacts";
    ok $contacts = Bric::Biz::Contact->href({
        person_id => ANY($person->get_id, $person2->get_id) }),
      "Look up by ANY(person_id)";
    is scalar keys %$contacts, 5, "Should have five contacts";

    # Try alertable.
    ok $contacts = Bric::Biz::Contact->href({ alertable => 1 }),
      "Look up by alertable";
    is scalar keys %$contacts, 5, "Should have five contacts";

    # Try description.
    ok $contacts = Bric::Biz::Contact->href({
        description => 'Primary Electronic Mail Address'
    }), "Look up by description";
    is scalar keys %$contacts, 2, "Should have two contacts";
    ok $contacts = Bric::Biz::Contact->href({ description => '%mail%' }),
      "Look up by description '%mail%";
    is scalar keys %$contacts, 5, "Should have five contacts";
    ok $contacts = Bric::Biz::Contact->href({
        description => ANY(
            'Primary Electronic Mail Address',
            'Secondary Electronic Mail Address',
        ),
    }), "Look up by ANY(description)";
    is scalar keys %$contacts, 5, "Should have five contacts";
}

##############################################################################
# Test the list_ids() method.
sub test_list_ids : Test(47) {
    my $self = shift;
    ok my $person = $self->person, "Construct a person object";
    ok my $person2 = $self->person, "Construct another person object";

    # Create some test records.
    for my $n (1..5) {
        my %args = %contact;
        # Make sure the name is unique.
        $args{value} = 'ovid@kineticode.com' if $n % 2;
        $args{type}  = 'Secondary Email' if $n % 2;
        ok( my $contact = Bric::Biz::Contact->new(\%args),
            "Create $args{value}" );
        ok( $contact->save, "Save $args{value}" );
        # Save the ID for deleting.
        $self->add_del_ids([$contact->get_id]);
        $person->add_new_contacts($contact) unless $n % 2;
        $person2->add_new_contacts($contact) if $n % 2;
    }
    ok $person->save, "Save the person object";
    ok $person2->save, "Save the other person object";

    # Try type.
    ok my @contact_ids = Bric::Biz::Contact->list_ids({ type => 'Primary Email' }),
      "Look up by type";
    is scalar @contact_ids, 2, "Should have two contact IDs";
    ok @contact_ids = Bric::Biz::Contact->list_ids({ type => '%Email%' }),
      "Look up by type '%Email%";
    is scalar @contact_ids, 5, "Should have five contact IDs";
    ok @contact_ids = Bric::Biz::Contact->list_ids({
        type => ANY('Primary Email', 'Secondary Email'),
    }), "Look up by ANY(type)";
    is scalar @contact_ids, 5, "Should have five contact IDs";
    like $_, qr/^\d+$/, "Should be an ID" for @contact_ids;

    # Try ID.
    my @ids = @contact_ids;
    ok @contact_ids = Bric::Biz::Contact->list_ids({ id => $ids[0] }),
      "Look up by id";
    is scalar @contact_ids, 1, "Should have one contact ID";
    ok @contact_ids = Bric::Biz::Contact->list_ids({ id => ANY(@ids) }),
      "Look up by ANY(id)";
    is scalar @contact_ids, 5, "Should have five contact IDs";

    # Try value.
    ok @contact_ids = Bric::Biz::Contact->list_ids({
        value => 'david@kineticode.com' }), "Look up by value";
    is scalar @contact_ids, 2, "Should have two contact IDs";
    ok @contact_ids = Bric::Biz::Contact->list_ids({ value => '%@kineticode.com' }),
      "Look up by value '%\@kineticode.com";
    is scalar @contact_ids, 5, "Should have five contact IDs";
    ok @contact_ids = Bric::Biz::Contact->list_ids({
        value => ANY('david@kineticode.com', 'ovid@kineticode.com'),
    }), "Look up by ANY(value)";
    is scalar @contact_ids, 5, "Should have five contact IDs";

    # Try person_id.
    ok @contact_ids = Bric::Biz::Contact->list_ids({ person_id => $person->get_id }),
      "Look up by person_id";
    is scalar @contact_ids, 2, "Should have two contact IDs";
    ok @contact_ids = Bric::Biz::Contact->list_ids({
        person_id => ANY($person->get_id, $person2->get_id) }),
      "Look up by ANY(person_id)";
    is scalar @contact_ids, 5, "Should have five contact IDs";

    # Try alertable.
    ok @contact_ids = Bric::Biz::Contact->list_ids({ alertable => 1 }),
      "Look up by alertable";
    is scalar @contact_ids, 5, "Should have five contact IDs";

    # Try description.
    ok @contact_ids = Bric::Biz::Contact->list_ids({
        description => 'Primary Electronic Mail Address'
    }), "Look up by description";
    is scalar @contact_ids, 2, "Should have two contact IDs";
    ok @contact_ids = Bric::Biz::Contact->list_ids({ description => '%mail%' }),
      "Look up by description '%mail%";
    is scalar @contact_ids, 5, "Should have five contact IDs";
    ok @contact_ids = Bric::Biz::Contact->list_ids({
        description => ANY(
            'Primary Electronic Mail Address',
            'Secondary Electronic Mail Address',
        ),
    }), "Look up by ANY(description)";
    is scalar @contact_ids, 5, "Should have five contact IDs";
}

1;
__END__
