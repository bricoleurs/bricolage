package Bric::Util::AlertType::DevTest;

use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Util::AlertType;
use Bric::Util::DBI qw(:junction);

sub table { 'alert_type' }

my %test_vals = (
    event_type_id => 1028,
    owner_id      => __PACKAGE__->user_id,
    name          => 'Testing!',
    subject       => 'Test Subject',
    message       => 'Test Message'
);

##############################################################################
# Test construtors.
##############################################################################
# Test lookup().
sub test_lookup : Test(10) {
    my $self = shift;
    ok( my $at = Bric::Util::AlertType->new(\%test_vals),
        "New AT with vals" );
    ok( $at->save, "Save AT" );
    ok( my $atid = $at->get_id, "Get AT ID" );
    $self->add_del_ids($atid);
    # Now look it up.
    ok( $at = Bric::Util::AlertType->lookup({ id => $atid}),
        "Look up AT $atid" );
    isa_ok($at, 'Bric::Util::AlertType');
    is( $at->get_event_type_id, $test_vals{event_type_id},
        "Check event_type_id = $test_vals{event_type_id}" );
    is( $at->get_owner_id, $test_vals{owner_id},
        "Check owner_id = $test_vals{owner_id}" );
    is( $at->get_name, $test_vals{name},
        "Check name = $test_vals{name}" );
    is( $at->get_subject, $test_vals{subject},
        "Check subject = $test_vals{subject}" );
    is( $at->get_message, $test_vals{message},
        "Check message = $test_vals{message}" );
}

##############################################################################
# Test list().
sub test_list : Test(56) {
    my $self = shift;
    # Create a new test_valsent group.
    ok( my $grp = Bric::Util::Grp::AlertType->new({
        name => 'Test AlertType Grp'
    }), "Create group" );

    # Create some test records.
    my @at_ids;
    for my $n (1..5) {
        my %args = %test_vals;
        # Make sure the name is unique.
        $args{name} .= $n;
        if ($n % 2) {
            $args{subject} .= $n;
            $args{event_type_id} += 1;
        }

        ok( my $at = Bric::Util::AlertType->new(\%args), "Create $args{name}" );
        ok( $at->save, "Save $args{name}" );
        # Save the ID for deleting.
        push @at_ids, $at->get_id;
        $self->add_del_ids($at_ids[-1]);
        $grp->add_member({ obj => $at }) if $n % 2;
    }

    ok( $grp->save, "Save group" );
    ok( my $grp_id = $grp->get_id, "Get group ID" );
    $self->add_del_ids($grp_id, 'grp');

    # Try id.
    ok my @ats = Bric::Util::AlertType->list({ id => $at_ids[0] }),
        'Search on id';
    is scalar @ats, 1, 'Should have 1 alert type';
    ok @ats = Bric::Util::AlertType->list({ id => ANY(@at_ids) }),
        'Search on ANY(id)';
    is scalar @ats, 5, 'Should have 5 alert types';
    isa_ok $_, 'Bric::Util::AlertType' for @ats;

    # Try name.
    ok @ats = Bric::Util::AlertType->list({ name => "$test_vals{name}1" }),
        'Search on name';
    is scalar @ats, 1, 'Should have 1 alert type';
    ok @ats = Bric::Util::AlertType->list({
        name => ANY("$test_vals{name}1", "$test_vals{name}2"),
    }), 'Search on ANY(name)';
    is scalar @ats, 2, 'Should have 2 alert types';
    ok @ats = Bric::Util::AlertType->list({ name => "$test_vals{name}%" }),
        qq{Search on name "$test_vals{name}%"};
    is scalar @ats, 5, 'Should have 5 alert types';

    # Try subject.
    ok @ats = Bric::Util::AlertType->list({
        subject => $test_vals{subject},
    }), "Search for subject '$test_vals{subject}'";
    is scalar @ats, 2, "Should have 2 alert types";
    ok @ats = Bric::Util::AlertType->list({
        subject => ANY($test_vals{subject}, "$test_vals{subject}1"),
    }), 'Search ANY(subject)';
    is scalar @ats, 3, "Should have 3 alert types";
    ok @ats = Bric::Util::AlertType->list({
        subject => "$test_vals{subject}%"
    }), "Search for subject '$test_vals{subject}%'";
    is scalar @ats, 5, 'Should have 5 alert types';

    # Try grp_id.
    ok @ats = Bric::Util::AlertType->list({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id'";
    is scalar @ats, 3, 'Should have 3 alert types';

    # Make sure we've got all the Group IDs we think we should have.
    my $all_grp_id = Bric::Util::AlertType::INSTANCE_GROUP_ID;
    foreach my $at (@ats) {
        my %grp_ids = map { $_ => 1 } @{ $at->get_grp_ids };
        ok $grp_ids{$all_grp_id} && $grp_ids{$grp_id},
          "Check for both IDs";
    }

    # Try deactivating one group membership.
    ok( my $mem = $grp->has_member({ obj => $ats[0] }), "Get member" );
    ok( $mem->deactivate->save, "Deactivate and save member" );

    # Now there should only be two using grp_id.
    ok( @ats = Bric::Util::AlertType->list({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id' again" );
    is( scalar @ats, 2, "Check for 2 alert types" );

    # Try ANY(grp_id).
    ok @ats = Bric::Util::AlertType->list({
        grp_id => ANY($grp_id, $all_grp_id)
    }), 'Search on ANY(grp_id)';
    is scalar @ats, 5, 'Should have 5 alert types';

    # Try event_type_id.
    ok @ats = Bric::Util::AlertType->list({
        event_type_id => $test_vals{event_type_id}
    }), qq{Search for event_type_id "$test_vals{event_type_id}"};
    is scalar @ats, 2, 'Should have 2 alert types';
    my $alt_event_id = $test_vals{event_type_id} + 1;
    ok @ats = Bric::Util::AlertType->list({
        event_type_id => ANY( $test_vals{event_type_id}, $alt_event_id ),
    }), 'Search on ANY(event_type_id)';
    is scalar @ats, 5, 'Should have 5 alert types';
    ok @ats = Bric::Util::AlertType->list({
        event_type_id => $alt_event_id
    }), qq{Search for event_type_id "$alt_event_id"};
    is scalar @ats, 3, 'Should have 3 alert types';

    # Try active.
    ok( @ats = Bric::Util::AlertType->list({ active => 1 }),
        "Look up active true" );
    is( scalar @ats, 5, "Check for 5 alert types" );

    # Deactivate one and try again.
    ok( $ats[0]->deactivate->save, "Deactivate an alert type" );
    ok( @ats = Bric::Util::AlertType->list({ active => 1 }),
        "Look up active true again" );
    is( scalar @ats, 4, "Check for 4 alert types" );
}

##############################################################################
# Test Class methods.
##############################################################################
# Test list_ids().
sub test_list_ids : Test(53) {
    my $self = shift;
    # Create a new test_valsent group.
    ok( my $grp = Bric::Util::Grp::AlertType->new({
        name => 'Test AlertType Grp'
    }), "Create group" );

    # Create some test records.
    my (@ats, @all_at_ids);
    for my $n (1..5) {
        my %args = %test_vals;
        # Make sure the name is unique.
        $args{name} .= $n;
        if ($n % 2) {
            $args{subject} .= $n;
            $args{event_type_id} += 1;
        }

        ok( my $at = Bric::Util::AlertType->new(\%args), "Create $args{name}" );
        ok( $at->save, "Save $args{name}" );
        # Save the ID for deleting.
        push @ats, $at;
        push @all_at_ids, $at->get_id;
        $self->add_del_ids($all_at_ids[-1]);
        $grp->add_member({ obj => $at }) if $n % 2;
    }

    ok( $grp->save, "Save group" );
    ok( my $grp_id = $grp->get_id, "Get group ID" );
    $self->add_del_ids($grp_id, 'grp');

    # Try id.
    ok my @at_ids = Bric::Util::AlertType->list_ids({ id => $all_at_ids[0] }),
        'Search on id';
    is scalar @at_ids, 1, 'Should have 1 alert type id';
    ok @at_ids = Bric::Util::AlertType->list_ids({ id => ANY(@all_at_ids) }),
        'Search on ANY(id)';
    is scalar @at_ids, 5, 'Should have 5 alert type ids';
    like $_, qr/^\d+$/, "$_ should be an id" for @at_ids;

    # Try name.
    ok @at_ids = Bric::Util::AlertType->list_ids({ name => "$test_vals{name}1" }),
        'Search on name';
    is scalar @at_ids, 1, 'Should have 1 alert type id';
    ok @at_ids = Bric::Util::AlertType->list_ids({
        name => ANY("$test_vals{name}1", "$test_vals{name}2"),
    }), 'Search on ANY(name)';
    is scalar @at_ids, 2, 'Should have 2 alert type ids';
    ok @at_ids = Bric::Util::AlertType->list_ids({ name => "$test_vals{name}%" }),
        qq{Search on name "$test_vals{name}%"};
    is scalar @at_ids, 5, 'Should have 5 alert type ids';

    # Try subject.
    ok @at_ids = Bric::Util::AlertType->list_ids({
        subject => $test_vals{subject},
    }), "Search for subject '$test_vals{subject}'";
    is scalar @at_ids, 2, "Should have 2 alert type ids";
    ok @at_ids = Bric::Util::AlertType->list_ids({
        subject => ANY($test_vals{subject}, "$test_vals{subject}1"),
    }), 'Search ANY(subject)';
    is scalar @at_ids, 3, "Should have 3 alert type ids";
    ok @at_ids = Bric::Util::AlertType->list_ids({
        subject => "$test_vals{subject}%"
    }), "Search for subject '$test_vals{subject}%'";
    is scalar @at_ids, 5, 'Should have 5 alert type ids';

    # Try grp_id.
    ok @at_ids = Bric::Util::AlertType->list_ids({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id'";
    is scalar @at_ids, 3, 'Should have 3 alert type ids';

    # Try deactivating one group membership.
    ok( my $mem = $grp->has_member({
        id => $at_ids[0],
        package => 'Bric::Util::AlertType',
    }), "Get member" );
    ok( $mem->deactivate->save, "Deactivate and save member" );

    # Now there should only be two using grp_id.
    ok( @at_ids = Bric::Util::AlertType->list_ids({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id' again" );
    is( scalar @at_ids, 2, "Check for 2 alert type ids" );

    # Try ANY(grp_id).
    my $all_grp_id = Bric::Util::AlertType::INSTANCE_GROUP_ID;
    ok @at_ids = Bric::Util::AlertType->list_ids({
        grp_id => ANY($grp_id, $all_grp_id)
    }), 'Search on ANY(grp_id)';
    is scalar @at_ids, 5, 'Should have 5 alert type ids';

    # Try event_type_id.
    ok @at_ids = Bric::Util::AlertType->list_ids({
        event_type_id => $test_vals{event_type_id}
    }), qq{Search for event_type_id "$test_vals{event_type_id}"};
    is scalar @at_ids, 2, 'Should have 2 alert type ids';
    my $alt_event_id = $test_vals{event_type_id} + 1;
    ok @at_ids = Bric::Util::AlertType->list_ids({
        event_type_id => ANY( $test_vals{event_type_id}, $alt_event_id ),
    }), 'Search on ANY(event_type_id)';
    is scalar @at_ids, 5, 'Should have 5 alert type ids';
    ok @at_ids = Bric::Util::AlertType->list_ids({
        event_type_id => $alt_event_id
    }), qq{Search for event_type_id "$alt_event_id"};
    is scalar @at_ids, 3, 'Should have 3 alert type ids';

    # Try active.
    ok( @at_ids = Bric::Util::AlertType->list_ids({ active => 1 }),
        "Look up active true" );
    is( scalar @at_ids, 5, "Check for 5 alert type ids" );

    # Deactivate one and try again.
    ok( $ats[0]->deactivate->save, "Deactivate an alert type id" );
    ok( @at_ids = Bric::Util::AlertType->list_ids({ active => 1 }),
        "Look up active true again" );
    is( scalar @at_ids, 4, "Check for 4 alert type ids" );
}

1;
__END__
