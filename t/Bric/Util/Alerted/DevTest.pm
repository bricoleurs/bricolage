package Bric::Util::Alerted::DevTest;

use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Util::Alert;
use Bric::Util::Alerted;
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
    my $at = Bric::Util::AlertType->new({ %at_args, @_ });
    $at->add_users('Primary Email' => __PACKAGE__->user_id);
    $at->save;
    $self->add_del_ids($at->get_id, 'alert_type');
    return $at;
}

sub user {
    my $self = shift;
    my $user = Bric::Biz::Person::User->new({
        login    => 'lwall',
        password => 'lwall',
    })->save;
    $self->add_del_ids($user->get_id, 'person'); # Cascades deelete to usr.
    return $user;
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
sub test_lookup : Test(19) {
    my $self = shift;
    no warnings qw(redefine);
    local *CORE::GLOBAL::time = sub () { $epoch };
    ok my $at    = $self->alert_type, 'Create new alert type';
    ok my $event = $self->event,      'Create new event';
    my $uid      = $self->user_id;

    ok my ($alert)  = Bric::Util::Alert->list({ event_id => $event->get_id }),
        "Find the alert";
    ok my ($alerted) = $alert->get_alerted, "Find alerted";

    my $alerted_id = $alerted->get_id;
    ok $alerted = Bric::Util::Alerted->lookup({ id => $alerted_id}),
        "Look up alerted by ID";

    isa_ok($alerted, 'Bric::Util::Alerted');
    is $alerted->get_id,        $alerted_id,    'Check alerted ID';
    is $alerted->get_alert_id,  $alert->get_id, 'Check alert ID';
    is $alerted->get_user_id,   $uid,           'Check user ID';
    is $alerted->get_ack_time,  undef,          'Check ack time';
    is $alerted->get_subject,   $subject,       'Check subject';
    is $alerted->get_message,   $message,       'Check message';
    is $alerted->get_timestamp, $now,           'Check timestamp';

    # Now acknowledge it.
    ok $alerted->acknowledge,                   'Acknowledge alerted';
    ok $alerted->save,                          'Save with acknowledgement';
    is $alerted->get_ack_time,  $now,           'Check ack time again';

    # Look it up again and make sure it was saved properly.
    ok $alert = Bric::Util::Alerted->lookup({ id => $alerted_id}),
        "Look up alerted by ID";
    is $alerted->get_id,        $alerted_id,    'Check alerted ID';
    is $alerted->get_ack_time,  $now,           'Check ack time';
}

##############################################################################
# Test list().
sub test_list : Test(73) {
    my $self = shift;
    no warnings qw(redefine);
    my $time = $epoch;
    local *CORE::GLOBAL::time = sub () { $time++ };

    ok my $at  = $self->alert_type, 'Create new alert type';
    ok my $at2 = $self->alert_type( name => 'Testing 2' ),
        'Create another alert type';

    ok my $user = $self->user, 'Create new user';
    ok $at2->add_users('Primary Email' => $user->get_id), 'Add user to alert type';
    ok $at2->save, 'Save alert type with new user';

    my @event_ids;
    my $wf_name = $wf->get_name;
    # Create some test records.
    for my $n (1..5) {
        $wf->set_name($wf_name . $n); # Muck with workflow name.
        ok my $event = $self->event, "Create event $n";
        push @event_ids, $event->get_id;
    }
    $wf->set_name($wf_name);      # Reset workflow name.

    # Try event_id.
    ok my @alerteds = Bric::Util::Alerted->list({ event_id => $event_ids[0] }),
        'Search on event_id';
    is scalar @alerteds, 3, 'Should have two alerteds';
    ok @alerteds = Bric::Util::Alerted->list({ event_id => ANY(@event_ids) }),
        'Search on ANY(event_id)';
    is scalar @alerteds, 15, 'Should have fifteen alerteds';
    isa_ok $_, 'Bric::Util::Alerted' for @alerteds;
    my @alerted_ids = map { $_->get_id } @alerteds;
    my @alert_ids   = map { $_->get_alert_id } @alerteds;

    # Try id.
    ok @alerteds = Bric::Util::Alerted->list({ id => $alerted_ids[0] }),
        "Search on id";
    is scalar @alerteds, 1, 'Should have one alerted';
    ok @alerteds = Bric::Util::Alerted->list({ id => ANY(@alerted_ids) }),
        'Search on ANY(id)';
    is scalar @alerteds, 15, 'Should have fifteen alerteds';

    # Try alert_id.
    ok @alerteds = Bric::Util::Alerted->list({ alert_id => $alert_ids[0] }),
        "Search on alert_id";
    is scalar @alerteds, 2, 'Should have two alerted';
    ok @alerteds = Bric::Util::Alerted->list({ alert_id => ANY(@alert_ids) }),
        'Search on ANY(alert_id)';
    is scalar @alerteds, 15, 'Should have fifteen alerteds';

    # Try alerted_type_id.
    ok @alerteds = Bric::Util::Alerted->list({
        alert_type_id => $at->get_id
    }), "Search on alert_type_id";
    is scalar @alerteds, 5, 'Should have five alerteds';
    ok @alerteds = Bric::Util::Alerted->list({
        alert_type_id => ANY($at->get_id, $at2->get_id)
    }), 'Search on ANY(alert_type_id)';
    is scalar @alerteds, 15, 'Should have fifteen alerteds';

    # Try subject.
    ok @alerteds = Bric::Util::Alerted->list({ subject => $subject . '1' }),
        "Search on subject";
    is scalar @alerteds, 3, 'Should have three alerteds';
    ok @alerteds = Bric::Util::Alerted->list({ subject => $subject . '%' }),
        "Search on subject + wildcard";
    is scalar @alerteds, 15, 'Should have fifteen alerteds';
    ok @alerteds = Bric::Util::Alerted->list({
        subject => ANY($subject . '1', $subject . '2'),
    }), 'Search on ANY(subject)';
    is scalar @alerteds, 6, 'Should have six alerteds';

    # Try name.
    ok @alerteds = Bric::Util::Alerted->list({ name => $subject . '1' }),
        "Search on name";
    is scalar @alerteds, 3, 'Should have three alerteds';
    ok @alerteds = Bric::Util::Alerted->list({ name => $subject . '%' }),
        "Search on name + wildcard";
    is scalar @alerteds, 15, 'Should have fifteen alerteds';
    ok @alerteds = Bric::Util::Alerted->list({
        name => ANY($subject . '1', $subject . '2'),
    }), 'Search on ANY(name)';
    is scalar @alerteds, 6, 'Should have six alerteds';

    # Try message.
    ok @alerteds = Bric::Util::Alerted->list({ message => $message . '1' }),
        "Search on message";
    is scalar @alerteds, 3, 'Should have three alerteds';
    ok @alerteds = Bric::Util::Alerted->list({ message => $message . '%' }),
        "Search on message + wildcard";
    is scalar @alerteds, 15, 'Should have fifteen alerteds';
    ok @alerteds = Bric::Util::Alerted->list({
        message => ANY($message . '1', $message . '2'),
    }), 'Search on ANY(message)';
    is scalar @alerteds, 6, 'Should have six alerteds';

    # Try timestamp.
    my $begin = strfdate($epoch + 1, '%Y-%m-%d %T');
    my $end = strfdate($time - 1, '%Y-%m-%d %T');
    ok @alerteds = Bric::Util::Alerted->list({ timestamp => $begin }),
        "Search on timestamp";
    is scalar @alerteds, 2, 'Should have two alerteds';
    ok @alerteds = Bric::Util::Alerted->list({ timestamp => ANY($begin, $end) }),
        "Search on ANY(timestamp)";
    is scalar @alerteds, 3, 'Should have three alerteds';

    ok @alerteds = Bric::Util::Alerted->list({
        timestamp => [ strfdate($epoch, '%Y-%m-%d %T') => $end ], # $begin works on Pg, but not MySQL
    }), "Search on timestamp array";
    is scalar @alerteds, 15, 'Should have fifteen alerteds';

    # Try undef ack_time.
    ok @alerteds = Bric::Util::Alerted->list({ ack_time => undef }),
        "Search on undef ack_time";
    is scalar @alerteds, 15, 'Should have fifteen alerteds';

    # Acknowledge them all.
    $begin = strfdate($time, '%Y-%m-%d %T');
    $_->acknowledge->save for @alerteds;
    $end = strfdate($time - 1, '%Y-%m-%d %T');

    # Try ack_time.
    ok @alerteds = Bric::Util::Alerted->list({ ack_time => $begin }),
        "Search on ack_time";
    is scalar @alerteds, 1, 'Should have one alerteds';
    ok @alerteds = Bric::Util::Alerted->list({ ack_time => ANY($begin, $end) }),
        "Search on ANY(ack_time)";
    is scalar @alerteds, 2, 'Should have two alerteds';

    ok @alerteds = Bric::Util::Alerted->list({
        ack_time => [ $begin => $end ],
    }), "Search on ack_time array";
    is scalar @alerteds, 15, 'Should have fifteen alerteds';
}

##############################################################################
# Test class methods.
##############################################################################
# Test list().
sub test_list_ids : Test(73) {
    my $self = shift;
    no warnings qw(redefine);
    my $time = $epoch;
    local *CORE::GLOBAL::time = sub () { $time++ };

    ok my $at  = $self->alert_type, 'Create new alert type';
    ok my $at2 = $self->alert_type( name => 'Testing 2' ),
        'Create another alert type';

    ok my $user = $self->user, 'Create new user';
    ok $at2->add_users('Primary Email' => $user->get_id), 'Add user to alert type';
    ok $at2->save, 'Save alert type with new user';

    my @event_ids;
    my $wf_name = $wf->get_name;
    # Create some test records.
    for my $n (1..5) {
        $wf->set_name($wf_name . $n); # Muck with workflow name.
        ok my $event = $self->event, "Create event $n";
        push @event_ids, $event->get_id;
    }
    $wf->set_name($wf_name);      # Reset workflow name.

    # Try event_id.
    ok my @alerted_ids = Bric::Util::Alerted->list_ids({ event_id => $event_ids[0] }),
        'Search on event_id';
    is scalar @alerted_ids, 3, 'Should have two alerted ids';
    ok @alerted_ids = Bric::Util::Alerted->list_ids({ event_id => ANY(@event_ids) }),
        'Search on ANY(event_id)';
    is scalar @alerted_ids, 15, 'Should have fifteen alerted ids';
    like $_, qr/^\d+$/, '$_ should be an id' for @alerted_ids;
    my @all_ids = @alerted_ids;
    my @alert_ids = Bric::Util::Alert->list_ids({ event_id => ANY(@event_ids) });

    # Try id.
    ok @alerted_ids = Bric::Util::Alerted->list_ids({ id => $all_ids[0] }),
        "Search on id";
    is scalar @alerted_ids, 1, 'Should have one alerted';
    ok @alerted_ids = Bric::Util::Alerted->list_ids({ id => ANY(@all_ids) }),
        'Search on ANY(id)';
    is scalar @alerted_ids, 15, 'Should have fifteen alerted ids';

    # Try alert_id.
    ok @alerted_ids = Bric::Util::Alerted->list_ids({ alert_id => $alert_ids[0] }),
        "Search on alert_id";
    is scalar @alerted_ids, 2, 'Should have two alerted';
    ok @alerted_ids = Bric::Util::Alerted->list_ids({ alert_id => ANY(@alert_ids) }),
        'Search on ANY(alert_id)';
    is scalar @alerted_ids, 15, 'Should have fifteen alerted ids';

    # Try alerted_type_id.
    ok @alerted_ids = Bric::Util::Alerted->list_ids({
        alert_type_id => $at->get_id
    }), "Search on alert_type_id";
    is scalar @alerted_ids, 5, 'Should have five alerted ids';
    ok @alerted_ids = Bric::Util::Alerted->list_ids({
        alert_type_id => ANY($at->get_id, $at2->get_id)
    }), 'Search on ANY(alert_type_id)';
    is scalar @alerted_ids, 15, 'Should have fifteen alerted ids';

    # Try subject.
    ok @alerted_ids = Bric::Util::Alerted->list_ids({ subject => $subject . '1' }),
        "Search on subject";
    is scalar @alerted_ids, 3, 'Should have three alerted ids';
    ok @alerted_ids = Bric::Util::Alerted->list_ids({ subject => $subject . '%' }),
        "Search on subject + wildcard";
    is scalar @alerted_ids, 15, 'Should have fifteen alerted ids';
    ok @alerted_ids = Bric::Util::Alerted->list_ids({
        subject => ANY($subject . '1', $subject . '2'),
    }), 'Search on ANY(subject)';
    is scalar @alerted_ids, 6, 'Should have six alerted ids';

    # Try name.
    ok @alerted_ids = Bric::Util::Alerted->list_ids({ name => $subject . '1' }),
        "Search on name";
    is scalar @alerted_ids, 3, 'Should have three alerted ids';
    ok @alerted_ids = Bric::Util::Alerted->list_ids({ name => $subject . '%' }),
        "Search on name + wildcard";
    is scalar @alerted_ids, 15, 'Should have fifteen alerted ids';
    ok @alerted_ids = Bric::Util::Alerted->list_ids({
        name => ANY($subject . '1', $subject . '2'),
    }), 'Search on ANY(name)';
    is scalar @alerted_ids, 6, 'Should have six alerted ids';

    # Try message.
    ok @alerted_ids = Bric::Util::Alerted->list_ids({ message => $message . '1' }),
        "Search on message";
    is scalar @alerted_ids, 3, 'Should have three alerted ids';
    ok @alerted_ids = Bric::Util::Alerted->list_ids({ message => $message . '%' }),
        "Search on message + wildcard";
    is scalar @alerted_ids, 15, 'Should have fifteen alerted ids';
    ok @alerted_ids = Bric::Util::Alerted->list_ids({
        message => ANY($message . '1', $message . '2'),
    }), 'Search on ANY(message)';
    is scalar @alerted_ids, 6, 'Should have six alerted ids';

    # Try timestamp.
    my $begin = strfdate($epoch + 1, '%Y-%m-%d %T');
    my $end = strfdate($time - 1, '%Y-%m-%d %T');
    ok @alerted_ids = Bric::Util::Alerted->list_ids({ timestamp => $begin }),
        "Search on timestamp";
    is scalar @alerted_ids, 2, 'Should have two alerted ids';
    ok @alerted_ids = Bric::Util::Alerted->list_ids({ timestamp => ANY($begin, $end) }),
        "Search on ANY(timestamp)";
    is scalar @alerted_ids, 3, 'Should have three alerted ids';

    ok @alerted_ids = Bric::Util::Alerted->list_ids({
        timestamp => [ strfdate($epoch, '%Y-%m-%d %T') => $end ], # $begin works on Pg, but not MySQL
    }), "Search on timestamp array";
    is scalar @alerted_ids, 15, 'Should have fifteen alerted ids';

    # Try undef ack_time.
    ok @alerted_ids = Bric::Util::Alerted->list_ids({ ack_time => undef }),
        "Search on undef ack_time";
    is scalar @alerted_ids, 15, 'Should have fifteen alerted ids';

    # Acknowledge them all.
    $begin = strfdate($time, '%Y-%m-%d %T');
    $_->acknowledge->save for Bric::Util::Alerted->list({ ack_time => undef });
    $end = strfdate($time - 1, '%Y-%m-%d %T');

    # Try ack_time.
    ok @alerted_ids = Bric::Util::Alerted->list_ids({ ack_time => $begin }),
        "Search on ack_time";
    is scalar @alerted_ids, 1, 'Should have one alerted ids';
    ok @alerted_ids = Bric::Util::Alerted->list_ids({ ack_time => ANY($begin, $end) }),
        "Search on ANY(ack_time)";
    is scalar @alerted_ids, 2, 'Should have two alerted ids';

    ok @alerted_ids = Bric::Util::Alerted->list_ids({
        ack_time => [ $begin => $end ],
    }), "Search on ack_time array";
    is scalar @alerted_ids, 15, 'Should have fifteen alerted ids';
}

1;
__END__
