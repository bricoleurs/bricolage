package Bric::Util::Event::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Util::Event;
use Bric::Biz::Workflow;

sub table { 'event' }

my $et_key = 'workflow_new';
my $et = Bric::Util::EventType->lookup({ key_name => $et_key });
my $et_key2 = 'workflow_add_desk';
my $et2 = Bric::Util::EventType->lookup({ key_name => $et_key2 });

my $user = Bric::Biz::Person::User->lookup({ id => __PACKAGE__->user_id });
my $wfid = 101; # The story workflow.
my $wf = Bric::Biz::Workflow->lookup({ id => $wfid });

my %event = ( obj  => $wf,
              user => $user,
              et   => $et );

##############################################################################
# Test constructors.
##############################################################################
# Test the lookup() method.
sub test_lookup : Test(24) {
    my $self = shift;

    # Construct a new event object.
    my %args = %event;
    ok( my $e = Bric::Util::Event->new(\%args), "Construct event" );
    # The event constructor calls save() itself.
    ok( my $eid = $e->get_id, "Get ID" );
    $self->add_del_ids($eid);

    # Make sure it's a good event.
    isa_ok($e, 'Bric::Util::Event');
    isa_ok($e, 'Bric');

    # Check a few attributes.
    is( $e->get_user_id, $user->get_id, "Check user ID" );
    is( $e->get_event_type_id, $et->get_id, "Check ET ID" );
    is( $e->get_obj_id, $wfid, "Check object ID" );
    is( $e->get_name, $et->get_name, "Check name" );
    is( $e->get_description, $et->get_description, "Check description" );
    is( $e->get_class, $et->get_class, "Check class" );
    # There should be no attributes or alerts.
    ok( ! defined $e->get_attr, "No attributes" );
    ok( ! defined $e->has_alerts, "No alerts" );

    # Now try the other event type.
    %args = %event;
    $args{et} = $et2;
    $args{attr} = { Desk => 'Whoo-wee!' };
    ok( $e = Bric::Util::Event->new(\%args), "Construct event" );
    # The event constructor calls save() itself.
    ok( $eid = $e->get_id, "Get ID" );
    $self->add_del_ids($eid);
    is( $e->get_user_id, $user->get_id, "Check user ID" );
    is( $e->get_event_type_id, $et2->get_id, "Check ET ID" );
    is( $e->get_obj_id, $wfid, "Check object ID" );
    is( $e->get_name, $et2->get_name, "Check name" );
    is( $e->get_description, $et2->get_description, "Check description" );
    is( $e->get_class, $et2->get_class, "Check class" );
    # There should be no alerts.
    ok( ! defined $e->has_alerts, "No alerts" );

    # Check the attributes.
    ok( my $attr = $e->get_attr, "Get attributes" );
    is( scalar keys %$attr, 1, "Check for one attribute" );
    is( $attr->{Desk}, 'Whoo-wee!', "Check desk attribute" );

}

##############################################################################
# Test list().
sub test_list : Test(49) {
    my $self = shift;

    # Create some test records.
    for my $n (1..5) {
        my %args = %event;
        if ($n % 2) {
            # There'll be three of these.
            $args{et} = $et2;
            $args{attr} = { Desk => 'Whiney' };
        } else {
            # There'll be two of these.
        }
        # Make sure the name is unique.
        ok( my $e = Bric::Util::Event->new(\%args), "Create event" );
        ok( $e->save, "Save event" );
        # Save the ID for deleting.
        $self->add_del_ids($e->get_id);
    }

    # Start with the "name" attribute.
    my $name = $et->get_name;
    ok(my @events = Bric::Util::Event->list({ name => $name}),
       "List name '$name'" );
    is(scalar @events, 2, "Check for 2 events");

    $name = $et2->get_name;
    ok(@events = Bric::Util::Event->list({ name => $name}),
       "List name '$name'" );
    is(scalar @events, 3, "Check for 3 events");

    # Try user_id.
    my $uid = $user->get_id;
    ok(@events = Bric::Util::Event->list({ user_id => $uid }),
       "List user_id '$uid'" );
    is(scalar @events, 5, "Check for 5 events");

    # Make sure that only three of them have attributes.
    my @with_attr = grep { $_->get_attr } @events;
    is(scalar @with_attr, 3, "Check for 3 events");

    # Try obj_id.
    ok(@events = Bric::Util::Event->list({ obj_id => $wfid }),
       "List obj_id '$wfid'" );
    is(scalar @events, 5, "Check for 5 events");

    # Try class_id.
    my $cid = Bric::Util::Class->lookup({ key_name => 'workflow' })->get_id;
    ok(@events = Bric::Util::Event->list({ class_id => $cid }),
       "List class_id '$cid'" );
    is(scalar @events, 5, "Check for 5 events");

    # Try class.
    my $class = 'Bric::Biz::Workflow';
    ok(@events = Bric::Util::Event->list({ class => $class }),
       "List class '$class'" );
    is(scalar @events, 5, "Check for 5 events");

    # Try key_name.
    ok(@events = Bric::Util::Event->list({ key_name => $et_key }),
       "List key_name '$et_key'" );
    is(scalar @events, 2, "Check for 2 events");

    ok(@events = Bric::Util::Event->list({ key_name => $et_key2 }),
       "List key_name '$et_key2'" );
    is(scalar @events, 3, "Check for 3 events");

    # Try description.
    my $desc = $et->get_description;
    ok(@events = Bric::Util::Event->list({ description => $desc }),
       "List description '$desc'" );
    is(scalar @events, 2, "Check for 2 events");

    $desc = $et2->get_description;
    ok(@events = Bric::Util::Event->list({ description => $desc }),
       "List description '$desc'" );
    is(scalar @events, 3, "Check for 3 events");

    # Try Limit.
    ok(@events = Bric::Util::Event->list({
        obj_id => $wfid,
        Limit  => 2,
    }), "List obj_id '$wfid' Limit 2" );
    is(scalar @events, 2, "Check for 2 events");

    # Try Offset.
    ok(@events = Bric::Util::Event->list({
        obj_id => $wfid,
        Offset  => 2,
    }), "List obj_id '$wfid' Offset 2" );
    is(scalar @events, 3, "Check for 3 events");

    # Try Order
    ok(@events = Bric::Util::Event->list({
        user_id => $uid,
        Order   => 'key_name',
    }), "List user_id '$uid' Order by 'key_name'" );
    is(scalar @events, 5, "Check for 5 events");
    is $events[$_]->get_key_name, 'workflow_add_desk',
        "Item $_ should be workfow_add_desk"
        for 0..2;
    is $events[$_]->get_key_name, 'workflow_new',
        "Item $_ should be workfow_new"
        for 3..4;

    # Try OrderDirection
    ok(@events = Bric::Util::Event->list({
        user_id        => $uid,
        Order          => 'key_name',
        OrderDirection => 'DESC',
    }), "List user_id '$uid' Order by 'key_name DESC'" );
    is(scalar @events, 5, "Check for 5 events");
    is $events[$_]->get_key_name, 'workflow_new',
        "Item $_ should be workfow_new"
        for 0..1;
    is $events[$_]->get_key_name, 'workflow_add_desk',
        "Item $_ should be workfow_add_desk"
        for 2..4;
}

##############################################################################
# Test list_ids().
sub test_list_ids : Test(34) {
    my $self = shift;

    # Create some test records.
    for my $n (1..5) {
        my %args = %event;
        if ($n % 2) {
            # There'll be three of these.
            $args{et} = $et2;
        } else {
            # There'll be two of these.
        }
        # Make sure the name is unique.
        ok( my $e = Bric::Util::Event->new(\%args), "Create event" );
        ok( $e->save, "Save event" );
        # Save the ID for deleting.
        $self->add_del_ids($e->get_id);
    }

    # Start with the "name" attribute.
    my $name = $et->get_name;
    ok(my @event_ids = Bric::Util::Event->list_ids({ name => $name}),
       "List IDs name '$name'" );
    is(scalar @event_ids, 2, "Check for 2 event IDs");

    $name = $et2->get_name;
    ok(@event_ids = Bric::Util::Event->list_ids({ name => $name}),
       "List IDs name '$name'" );
    is(scalar @event_ids, 3, "Check for 3 event IDs");

    # Try user_id.
    my $uid = $user->get_id;
    ok(@event_ids = Bric::Util::Event->list_ids({ user_id => $uid }),
       "List IDs user_id '$uid'" );
    is(scalar @event_ids, 5, "Check for 5 event IDs");

    # Try obj_id.
    ok(@event_ids = Bric::Util::Event->list_ids({ obj_id => $wfid }),
       "List IDs obj_id '$wfid'" );
    is(scalar @event_ids, 5, "Check for 5 event IDs");

    # Try class_id.
    my $cid = Bric::Util::Class->lookup({ key_name => 'workflow' })->get_id;
    ok(@event_ids = Bric::Util::Event->list_ids({ class_id => $cid }),
       "List IDs class_id '$cid'" );
    is(scalar @event_ids, 5, "Check for 5 event IDs");

    # Try class.
    my $class = 'Bric::Biz::Workflow';
    ok(@event_ids = Bric::Util::Event->list_ids({ class => $class }),
       "List IDs class '$class'" );
    is(scalar @event_ids, 5, "Check for 5 event IDs");

    # Try key_name.
    ok(@event_ids = Bric::Util::Event->list_ids({ key_name => $et_key }),
       "List IDs key_name '$et_key'" );
    is(scalar @event_ids, 2, "Check for 2 event IDs");

    ok(@event_ids = Bric::Util::Event->list_ids({ key_name => $et_key2 }),
       "List IDs key_name '$et_key2'" );
    is(scalar @event_ids, 3, "Check for 3 event IDs");

    # Try description.
    my $desc = $et->get_description;
    ok(@event_ids = Bric::Util::Event->list_ids({ description => $desc }),
       "List IDs description '$desc'" );
    is(scalar @event_ids, 2, "Check for 2 event IDs");

    $desc = $et2->get_description;
    ok(@event_ids = Bric::Util::Event->list_ids({ description => $desc }),
       "List IDs description '$desc'" );
    is(scalar @event_ids, 3, "Check for 3 event IDs");

    # Try Limit.
    ok(@event_ids = Bric::Util::Event->list({
        obj_id => $wfid,
        Limit  => 2,
    }), "List obj_id '$wfid' Limit 2" );
    is(scalar @event_ids, 2, "Check for 2 event IDs");

    # Try Offset.
    ok(@event_ids = Bric::Util::Event->list({
        obj_id => $wfid,
        Offset  => 2,
    }), "List obj_id '$wfid' Offset 2" );
    is(scalar @event_ids, 3, "Check for 3 event IDs");
}

##############################################################################
# Test instance methods.
##############################################################################
# Test save() not necessary, because saving is tested by test_lookup().

1;
__END__
