package Bric::Dist::Action::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Dist::ServerType;
use Bric::Dist::ActionType;
use Bric::Dist::Action;
use Bric::Dist::Action::Mover;
use Bric::Dist::Action::Email;

sub table {'action'}
sub class { 'Bric::Dist::Action' }

my %act = ( type => 'Move' );

my $move_at = Bric::Dist::ActionType->lookup({ id => 1 });
my $email_at = Bric::Dist::ActionType->lookup({ id => 4 });

sub setup : Test(setup) {
    my $self = shift;
    my $dest = Bric::Dist::ServerType->new({ name => 'Bogus',
                                             description => 'Bogus server type',
                                             site_id     => 100,
                                             move_method => 'File System'
                                           });
    $dest->save;
    $act{server_type_id} = $dest->get_id;
    $self->add_del_ids($act{server_type_id}, 'server_type');
    $self->{dest} = $dest;
}

sub cleanup_attrs : Test(teardown) {
    Bric::Util::DBI::prepare(
        qq{DELETE FROM attr_action WHERE id > 1023}
    )->execute;
}

##############################################################################
# Test constructors.
##############################################################################
# Test the lookup() method.
sub test_lookup : Test(8) {
    my $self = shift;
    my $class = $self->class;
    my %args = %act;
    ok( my $act = $class->new(\%args), "Create action" );
    ok( $act->save, "Save the action" );
    ok( my $did = $act->get_id, "Get the action ID" );
    $self->add_del_ids($did);
    ok( $act = $class->lookup({ id => $did }),
        "Look up the new action" );
    is( $act->get_id, $did, "Check that the ID is the same" );
    # Check a few attributes.
    ok( $act->is_active, "Check that it's activated" );
    is( $act->get_type, $args{type}, "Check the type" );
    is( $act->get_ord, 1, "Check the ord" );
}

##############################################################################
# Test the list() method.
sub test_list : Test(22) {
    my $self = shift;
    my $class = $self->class;

    # Create some test records.
    for my $n (1..5) {
        my %args = %act;
        # Make sure the name is unique.
        $args{type} = 'Email' if $n % 2;
        ok( my $act = $class->new(\%args),
            "Create $args{type} $n" );
        if ($n % 2) {
            $act->set_to('you@example.com');
        } else {
            $act->deactivate unless $n % 2;
        }
        ok( $act->save, "Save $args{type} $n" );
        # Save the ID for deleting.
        $self->add_del_ids($act->get_id);
    }

    # Try type.
    ok( my @acts = $class->list({ type => 'Email' }),
        "Look up type 'Email'" );
    is( scalar @acts, 3, "Check for 3 actions" );

    # Try type + wildcard.
    ok( @acts = $class->list({ type => "Mo%" }),
        "Look up type 'Mo%'" );
    is( scalar @acts, 2, "Check for 2 actions" );

    # Try description.
    my $desc = $move_at->get_description;
    ok( @acts = $class->list({ description => $desc }),
        "Look up description '$desc'" );
    is( scalar @acts, 2, "Check for 2 actions" );

    # Try description + wildcard.
    $desc = substr $email_at->get_description, 0, 4;
    ok( @acts = $class->list({ description => "$desc%" }),
        "Look up description '$desc%'" );
    is( scalar @acts, 3, "Check for 3 actions" );

    # Try server_type_id.
    ok( @acts = $class->list
        ({ server_type_id => $act{server_type_id} }),
        "Look up server_type_id '$act{server_type_id}'" );
    is( scalar @acts, 5, "Check for 5 actions" );

    # Try active.
    ok( @acts = $class->list({ active => 1 }),
        "Look up active => 1" );
    is( scalar @acts, 3, "Check for 3 actions" );
}


##############################################################################
# Test the href() method.
sub test_href : Test(22) {
    my $self = shift;
    my $class = $self->class;

    # Create some test records.
    for my $n (1..5) {
        my %args = %act;
        # Make sure the name is unique.
        $args{type} = 'Email' if $n %2;
        ok( my $act = $class->new(\%args),
            "Create $args{type} $n" );
        if ($n % 2) {
            $act->set_to('you@example.com');
        } else {
            $act->deactivate unless $n % 2;
        }
        ok( $act->save, "Save $args{type} $n" );
        # Save the ID for deleting.
        $self->add_del_ids($act->get_id);
    }

    # Try type.
    ok( my $acts = $class->href({ type => 'Email' }),
        "Look up type 'Email'" );
    is( scalar keys %$acts, 3, "Check for 3 actions" );

    # Try type + wildcard.
    ok( $acts = $class->href({ type => "Mo%" }),
        "Look up type 'Mo%'" );
    is( scalar keys %$acts, 2, "Check for 2 actions" );

    # Try description.
    my $desc = $move_at->get_description;
    ok( $acts = $class->href({ description => $desc }),
        "Look up description '$desc'" );
    is( scalar keys %$acts, 2, "Check for 2 actions" );

    # Try description + wildcard.
    $desc = substr $email_at->get_description, 0, 4;
    ok( $acts = $class->href({ description => "$desc%" }),
        "Look up description '$desc%'" );
    is( scalar keys %$acts, 3, "Check for 3 actions" );

    # Try server_type_id.
    ok( $acts = $class->href
        ({ server_type_id => $act{server_type_id} }),
        "Look up server_type_id '$act{server_type_id}'" );
    is( scalar keys %$acts, 5, "Check for 5 actions" );

    # Try active.
    ok( $acts = $class->href({ active => 1 }),
        "Look up active => 1" );
    is( scalar keys %$acts, 3, "Check for 3 actions" );
}

##############################################################################
# Test class methods.
##############################################################################
# Test the list_ids() method.
sub test_list_ids : Test(22) {
    my $self = shift;
    my $class = $self->class;

    # Create some test records.
    for my $n (1..5) {
        my %args = %act;
        # Make sure the name is unique.
        $args{type} = 'Email' if $n %2;
        ok( my $act = $class->new(\%args),
            "Create $args{type} $n" );
        if ($n % 2) {
            $act->set_to('you@example.com');
        } else {
            $act->deactivate unless $n % 2;
        }
        ok( $act->save, "Save $args{type} $n" );
        # Save the ID for deleting.
        $self->add_del_ids($act->get_id);
    }

    # Try type.
    ok( my @act_ids = $class->list_ids({ type => 'Email' }),
        "Look up type 'Email'" );
    is( scalar @act_ids, 3, "Check for 3 action IDs" );

    # Try type + wildcard.
    ok( @act_ids = $class->list_ids({ type => "Mo%" }),
        "Look up type 'Mo%'" );
    is( scalar @act_ids, 2, "Check for 2 action IDs" );

    # Try description.
    my $desc = $move_at->get_description;
    ok( @act_ids = $class->list_ids({ description => $desc }),
        "Look up description '$desc'" );
    is( scalar @act_ids, 2, "Check for 2 action IDs" );

    # Try description + wildcard.
    $desc = substr $email_at->get_description, 0, 4;
    ok( @act_ids = $class->list_ids({ description => "$desc%" }),
        "Look up description '$desc%'" );
    is( scalar @act_ids, 3, "Check for 3 action IDs" );

    # Try server_type_id.
    ok( @act_ids = $class->list_ids
        ({ server_type_id => $act{server_type_id} }),
        "Look up server_type_id '$act{server_type_id}'" );
    is( scalar @act_ids, 5, "Check for 5 action IDs" );

    # Try active.
    ok( @act_ids = $class->list_ids({ active => 1 }),
        "Look up active => 1" );
    is( scalar @act_ids, 3, "Check for 3 action IDs" );
}

##############################################################################
# Test my_meths().
sub test_my_meths : Test(8) {
    my $self = shift;
    my $class = $self->class;
    ok( my $meths = $class->my_meths, "Get my_meths" );
    isa_ok($meths, 'HASH', "my_meths is a hash" );
    is( $meths->{type}{type}, 'short', "Check name type" );
    ok( $meths = $class->my_meths(1), "Get my_meths array ref" );
    isa_ok( $meths, 'ARRAY', "my_meths(1) is an array" );
    (is $meths->[0]->{name}, 'type', "Check first meth name" );

    # Try the identifier methods.
    ok( my $act = $class->new({ type => 'Email' }),
        "Create action" );
    my @meths = $act->my_meths(0, 1);
    is( scalar @meths, 0, "Check for no meths" );
}

##############################################################################
# Test set_type().
sub test_set_type : Test(8) {
    ok( my $act = Bric::Dist::Action->new(\%act), "Create action" );
    isa_ok($act, 'Bric::Dist::Action::Mover');
    isa_ok($act, 'Bric::Dist::Action');
    isa_ok($act, 'Bric');

    # Change it!
    ok( $act->set_type('Email'), "Set type to 'Email'" );
    isa_ok($act, 'Bric::Dist::Action::Email');
    isa_ok($act, 'Bric::Dist::Action');
    isa_ok($act, 'Bric');
}

##############################################################################
# Test list_types. Increase the number of tests for each new action added.
sub test_list_types : Test(7) {
    my $self = shift;
    ok( my @types = Bric::Dist::Action->list_types, "Get types" );
    my $i;
    foreach my $type (@types) {
        ++$i;
        ok( my $act = Bric::Dist::Action->new({ type => $type }),
            "Create $type action" );
        isa_ok($act, 'Bric::Dist::Action');
    }
    return "Remaining types not loaded" if $i < 7;
}

1;
__END__
