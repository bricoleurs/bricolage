package Bric::Util::AlertType::DevTest;

use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Util::AlertType;

sub table { 'alert_type' }

my %test_vals = ( event_type_id => 1028,
                  owner_id      => 0,
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
sub test_list : Test(28) {
    my $self = shift;
    # Create a new test_valsent group.
    ok( my $grp = Bric::Util::Grp::AlertType->new
        ({ name => 'Test AlertType Grp' }),
        "Create group" );

    # Create some test records.
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
        $self->add_del_ids($at->get_id);
        $grp->add_member({ obj => $at }) if $n % 2;
    }

    ok( $grp->save, "Save group" );
    ok( my $grp_id = $grp->get_id, "Get group ID" );
    $self->add_del_ids($grp_id, 'grp');

    # Try name + wildcard.
    ok( my @ats = Bric::Util::AlertType->list({ name => "$test_vals{name}%" }),
        "Look up name $test_vals{name}%" );
    is( scalar @ats, 5, "Check for 5 alert types" );

    # Try subject.
    ok( @ats = Bric::Util::AlertType->list
        ({ subject => "$test_vals{subject}" }),
        "Look up subject '$test_vals{subject}'" );
    is( scalar @ats, 2, "Check for 2 alert types" );

    # Try subject + wildcard.
    ok( @ats = Bric::Util::AlertType->list
        ({ subject => "$test_vals{subject}%" }),
        "Look up subject '$test_vals{subject}%'" );
    is( scalar @ats, 5, "Check for 5 alert types" );

    # Try grp_id.
    ok( @ats = Bric::Util::AlertType->list({ grp_id => $grp_id }),
        "Look up grp_id $grp_id" );
    is( scalar @ats, 3, "Check for 3 alert types" );
    # Make sure we've got all the Group IDs we think we should have.
    my $all_grp_id = Bric::Util::AlertType::INSTANCE_GROUP_ID;
    foreach my $at (@ats) {
        my %grp_ids = map { $_ => 1 } @{ $at->get_grp_ids };
        ok( $grp_ids{$all_grp_id} && $grp_ids{$grp_id},
          "Check for both IDs" );
    }

    # Try event_type_id.
    ok( @ats = Bric::Util::AlertType->list
        ({ event_type_id => $test_vals{event_type_id}}),
        "Lookup by event_type_id '$test_vals{event_type_id}'" );
    is( scalar @ats, 2, "Check for 2 alert types" );
    ok( @ats = Bric::Util::AlertType->list
        ({ event_type_id => $test_vals{event_type_id} + 1}),
        "Lookup by event_type_id '" . ($test_vals{event_type_id} + 1) . "'" );
    is( scalar @ats, 3, "Check for 3 alert types" );
}

1;
__END__
