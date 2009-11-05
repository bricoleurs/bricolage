package Bric::Util::Alert::DevTest;

use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Util::Alert;
use Bric::Util::AlertType;
use Bric::Util::Event;
use Bric::Biz::Workflow;
use Bric::Util::DBI qw(:junction);
use Bric::Util::Time qw(strfdate);

sub table { 'alert' }

my $epoch = CORE::time;
my $now   = strfdate($epoch, '%Y-%m-%d %T');
my $user  = Bric::Biz::Person::User->lookup({ id => __PACKAGE__->user_id });
my $wf    = Bric::Biz::Workflow->lookup({ id => 101 });
my $et    = Bric::Util::EventType->lookup({ key_name => 'workflow_new'});

my %at_args = (
    event_type_id => $et->get_id,
    owner_id      => __PACKAGE__->user_id,
    name          => 'Testing!',
    subject       => 'Test $name',
    message       => 'Test Message $name'
);

(my $subject = $at_args{subject}) =~ s/\$name/$wf->get_name/e;
(my $message = $at_args{message}) =~ s/\$name/$wf->get_name/e;

sub alert_type {
    my $self = shift;
    my $at = Bric::Util::AlertType->new({ %at_args, @_ })->save;
    $self->add_del_ids($at->get_id, 'alert_type');
    return $at;
}

sub event {
    my $self = shift;
    my $event = Bric::Util::Event->new({
        obj       => $wf,
        user      => $user,
        et        => $et,
    })->save;
    $self->add_del_ids($event->get_id, 'event');
    return $event;
}

##############################################################################
# Test construtors.
##############################################################################
# Test lookup().
sub test_lookup : Test(10) {
    my $self = shift;
    no warnings qw(redefine);
    local *CORE::GLOBAL::time = sub () { $epoch };
    ok my $at    = $self->alert_type, 'Create new alert type';
    ok my $event = $self->event,      'Create new event';

    ok my ($alert)  = Bric::Util::Alert->list({ event_id => $event->get_id }),
        "Find the alert";
    ok $alert = Bric::Util::Alert->lookup({ id => $alert->get_id}),
        "Look up alert by ID";

    isa_ok($alert, 'Bric::Util::Alert');
    is $alert->get_event_id,  $event->get_id, 'Check event ID';
    is $alert->get_name,      $subject,       'Check name is same as subject';
    is $alert->get_subject,   $subject,       'Check subject';
    is $alert->get_message,   $message,       'Check message';
    is $alert->get_timestamp, $now,           'Check timestamp';
}

##############################################################################
# Test list().
sub test_list : Test(53) {
    my $self = shift;
    no warnings qw(redefine);
    my $time = $epoch;
    local *CORE::GLOBAL::time = sub () { $time++ };

    ok my $at  = $self->alert_type, 'Create new alert type';
    ok my $at2 = $self->alert_type( name => 'Testing 2' ),
        'Create another alert type';
    my @event_ids;
    my $wf_name = $wf->get_name;
    # Create some test records.
    for my $n (1..5) {
        $wf->set_name($wf_name . $n); # Muck with workflow name.
        ok my $event = $self->event, "Create event $n";
        push @event_ids, $event->get_id;
    }
    $wf->set_name($wf_name);      # Reset workflow name.

    # Try Event ID.
    ok my @alerts = Bric::Util::Alert->list({ event_id => $event_ids[0] }),
        'Search on event_id';
    is scalar @alerts, 2, 'Should have two alerts';
    ok @alerts = Bric::Util::Alert->list({ event_id => ANY(@event_ids) }),
        'Search on ANY(event_id)';
    is scalar @alerts, 10, 'Should have ten alerts';
    isa_ok $_, 'Bric::Util::Alert' for @alerts;
    my @alert_ids = map { $_->get_id } @alerts;

    # Try ID.
    ok @alerts = Bric::Util::Alert->list({ id => $alert_ids[0] }),
        "Search on id";
    is scalar @alerts, 1, 'Should have one alert';
    ok @alerts = Bric::Util::Alert->list({ id => ANY(@alert_ids) }),
        "Search on ANY(id)";
    is scalar @alerts, 10, 'Should have ten alerts';

    # Try alert_type_id.
    ok @alerts = Bric::Util::Alert->list({ alert_type_id => $at->get_id }),
        "Search on alert_type_id";
    is scalar @alerts, 5, 'Should have five alerts';
    ok @alerts = Bric::Util::Alert->list({
        alert_type_id => ANY($at->get_id, $at2->get_id)
    }), "Search on ANY(alert_type_id)";
    is scalar @alerts, 10, 'Should have ten alerts';

    # Try subject.
    ok @alerts = Bric::Util::Alert->list({ subject => $subject . '1' }),
        "Search on subject";
    is scalar @alerts, 2, 'Should have two alerts';
    ok @alerts = Bric::Util::Alert->list({ subject => $subject . '%' }),
        "Search on subject + wildcard";
    is scalar @alerts, 10, 'Should have ten alerts';
    ok @alerts = Bric::Util::Alert->list({
        subject => ANY($subject . '1', $subject . '2'),
    }), "Search on ANY(subject)";
    is scalar @alerts, 4, 'Should have four alerts';

    # Try name.
    ok @alerts = Bric::Util::Alert->list({ name => $subject . '1' }),
        "Search on name";
    is scalar @alerts, 2, 'Should have two alerts';
    ok @alerts = Bric::Util::Alert->list({ name => $subject . '%' }),
        "Search on name + wildcard";
    is scalar @alerts, 10, 'Should have ten alerts';
    ok @alerts = Bric::Util::Alert->list({
        name => ANY($subject . '1', $subject . '2'),
    }), "Search on ANY(name)";
    is scalar @alerts, 4, 'Should have four alerts';

    # Try message.
    ok @alerts = Bric::Util::Alert->list({ message => $message . '1' }),
        "Search on message";
    is scalar @alerts, 2, 'Should have two alerts';
    ok @alerts = Bric::Util::Alert->list({ message => $message . '%' }),
        "Search on message + wildcard";
    is scalar @alerts, 10, 'Should have ten alerts';
    ok @alerts = Bric::Util::Alert->list({
        message => ANY($message . '1', $message . '2'),
    }), "Search on ANY(message)";
    is scalar @alerts, 4, 'Should have four alerts';

    # Try timestamp.
    my $begin = strfdate($epoch + 1, '%Y-%m-%d %T');
    my $end = strfdate($time - 1, '%Y-%m-%d %T');
    ok @alerts = Bric::Util::Alert->list({ timestamp => $begin }),
        "Search on timestamp";
    is scalar @alerts, 1, 'Should have one alert';
    ok @alerts = Bric::Util::Alert->list({ timestamp => ANY($begin, $end) }),
        "Search on ANY(timestamp)";
    is scalar @alerts, 2, 'Should have two alerts';

    # Try time_start and time_end.
    ok @alerts = Bric::Util::Alert->list({
        time_start => strfdate($epoch, '%Y-%m-%d %T'), # $begin works on Pg, but not MySQL
        time_end   => $end,
    }), "Search on time_start and time_end";
    is scalar @alerts, 10, 'Should have ten alerts';
}

##############################################################################
# Test class methods.
##############################################################################
# Test list_ids().
sub test_list_ids : Test(53) {
    my $self = shift;
    no warnings qw(redefine);
    my $time = $epoch;
    local *CORE::GLOBAL::time = sub () { $time++ };

    ok my $at  = $self->alert_type, 'Create new alert type';
    ok my $at2 = $self->alert_type( name => 'Testing 2' ),
        'Create another alert type';
    my @event_ids;
    my $wf_name = $wf->get_name;
    # Create some test records.
    for my $n (1..5) {
        $wf->set_name($wf_name . $n); # Muck with workflow name.
        ok my $event = $self->event, "Create event $n";
        push @event_ids, $event->get_id;
    }
    $wf->set_name($wf_name);      # Reset workflow name.

    # Try Event ID.
    ok my @alert_ids = Bric::Util::Alert->list_ids({ event_id => $event_ids[0] }),
        'Search on event_id';
    is scalar @alert_ids, 2, 'Should have two alert IDs';
    ok @alert_ids = Bric::Util::Alert->list_ids({ event_id => ANY(@event_ids) }),
        'Search on ANY(event_id)';
    is scalar @alert_ids, 10, 'Should have ten alert IDs';
    like $_, qr/^\d+$/, '$_ should be an ID' for @alert_ids;
    my @all_ids = @alert_ids;

    # Try ID.
    ok @alert_ids = Bric::Util::Alert->list_ids({ id => $all_ids[0] }),
        "Search on id";
    is scalar @alert_ids, 1, 'Should have one alert';
    ok @alert_ids = Bric::Util::Alert->list_ids({ id => ANY(@all_ids) }),
        "Search on ANY(id)";
    is scalar @alert_ids, 10, 'Should have ten alert IDs';

    # Try alert_type_id.
    ok @alert_ids = Bric::Util::Alert->list_ids({ alert_type_id => $at->get_id }),
        "Search on alert_type_id";
    is scalar @alert_ids, 5, 'Should have five alert IDs';
    ok @alert_ids = Bric::Util::Alert->list_ids({
        alert_type_id => ANY($at->get_id, $at2->get_id)
    }), "Search on ANY(alert_type_id)";
    is scalar @alert_ids, 10, 'Should have ten alert IDs';

    # Try subject.
    ok @alert_ids = Bric::Util::Alert->list_ids({ subject => $subject . '1' }),
        "Search on subject";
    is scalar @alert_ids, 2, 'Should have two alerts';
    ok @alert_ids = Bric::Util::Alert->list_ids({ subject => $subject . '%' }),
        "Search on subject + wildcard";
    is scalar @alert_ids, 10, 'Should have ten alert IDs';
    ok @alert_ids = Bric::Util::Alert->list_ids({
        subject => ANY($subject . '1', $subject . '2'),
    }), "Search on ANY(subject)";
    is scalar @alert_ids, 4, 'Should have four alert IDs';

    # Try name.
    ok @alert_ids = Bric::Util::Alert->list_ids({ name => $subject . '1' }),
        "Search on name";
    is scalar @alert_ids, 2, 'Should have two alerts';
    ok @alert_ids = Bric::Util::Alert->list_ids({ name => $subject . '%' }),
        "Search on name + wildcard";
    is scalar @alert_ids, 10, 'Should have ten alert IDs';
    ok @alert_ids = Bric::Util::Alert->list_ids({
        name => ANY($subject . '1', $subject . '2'),
    }), "Search on ANY(name)";
    is scalar @alert_ids, 4, 'Should have four alert IDs';

    # Try message.
    ok @alert_ids = Bric::Util::Alert->list_ids({ message => $message . '1' }),
        "Search on message";
    is scalar @alert_ids, 2, 'Should have two alerts';
    ok @alert_ids = Bric::Util::Alert->list_ids({ message => $message . '%' }),
        "Search on message + wildcard";
    is scalar @alert_ids, 10, 'Should have ten alert IDs';
    ok @alert_ids = Bric::Util::Alert->list_ids({
        message => ANY($message . '1', $message . '2'),
    }), "Search on ANY(message)";
    is scalar @alert_ids, 4, 'Should have four alert IDs';

    # Try timestamp.
    my $begin = strfdate($epoch + 1, '%Y-%m-%d %T');
    my $end = strfdate($time - 1, '%Y-%m-%d %T');
    ok @alert_ids = Bric::Util::Alert->list_ids({ timestamp => $begin }),
        "Search on timestamp";
    is scalar @alert_ids, 1, 'Should have one alert';
    ok @alert_ids = Bric::Util::Alert->list_ids({ timestamp => ANY($begin, $end) }),
        "Search on ANY(timestamp)";
    is scalar @alert_ids, 2, 'Should have two alert IDs';

    # Try time_start and time_end.
    ok @alert_ids = Bric::Util::Alert->list_ids({
        time_start => strfdate($epoch, '%Y-%m-%d %T'), # $begin works on Pg, but not MySQL
        time_end   => $end,
    }), "Search on time_start and time_end";
    is scalar @alert_ids, 10, 'Should have ten alert IDs';
}

1;
__END__
