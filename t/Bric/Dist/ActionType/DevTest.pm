package Bric::Dist::ActionType::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Dist::ServerType;
use Bric::Dist::ActionType;
use Bric::Util::DBI qw(:junction);

sub table {'action_type'}
sub class { 'Bric::Dist::ActionType' }

##############################################################################
# Test constructors.
##############################################################################
# Test the lookup() method.
sub test_lookup : Test(6) {
    my $self = shift;
    my $class = $self->class;
    ok my $at = $class->lookup({ id => 1 }),
        'Look up the "Move" action by ID';
    is $at->get_id, 1, 'Should be ID 1';
    is $at->get_name, 'Move', 'Should have the name "Move"';

    ok $at = $class->lookup({ name => 'move' }), 'Look up the "Move" action';
    is $at->get_id, 1, 'Should be ID 1';
    is $at->get_name, 'Move', 'Should have the name "Move"';
}

##############################################################################
# Test the list() method.
sub test_list : Test(28) {
    my $self = shift;
    my $class = $self->class;

    # Try ID.
    ok my @ats = $class->list({ id => 1 }), 'Look up by ID';
    is scalar @ats, 1, 'Should have one AT.';
    ok @ats = $class->list({ id => ANY(1, 4) }), 'Look up by ANY(ID)';
    is scalar @ats, 2, 'Should have two ATs.';
    isa_ok $_, 'Bric::Dist::ActionType' for @ats;

    # Try name.
    ok @ats = $class->list({ name => 'Move' }), 'Look up by name';
    is scalar @ats, 1, 'Should have one AT.';
    ok @ats = $class->list({ name => '%' }), 'Look up by name wildcard';
    is scalar @ats, 3, 'Should have three ATs.';
    ok @ats = $class->list({ name => ANY(qw(Move Email)) }),
        'Look up by ANY(name)';
    is scalar @ats, 2, 'Should have two ATs.';

    # Try description.
    ok @ats = $class->list({ description => 'Email resources.' }),
        'Look up by description';
    is scalar @ats, 1, 'Should have one AT.';
    ok @ats = $class->list({ description => '%' }),
        'Look up by description wildcard';
    is scalar @ats, 3, 'Should have three ATs.';
    ok @ats = $class->list({ description => ANY(qw(email% puts%)) }),
        'Look up by ANY(description)';
    is scalar @ats, 2, 'Should have two ATs.';

    # Try media_type.
    ok @ats = $class->list({ media_type => 'text/html' }),
        'Look up by media_type';
    is scalar @ats, 1, 'Should have one AT.';
    ok @ats = $class->list({ media_type => 'text/%' }),
        'Look up by media_type wildcard';
    is scalar @ats, 1, 'Should have one AT.';
    ok @ats = $class->list({ media_type => ANY(qw(text% none)) }),
        'Look up by ANY(media_type)';
    is scalar @ats, 3, 'Should have three ATs.';

    # Try media_type_id.
    ok @ats = $class->list({ media_type_id => 0 }),
        'Look up by media_type_id';
    is scalar @ats, 2, 'Should have two ATs.';
    ok @ats = $class->list({ media_type_id => ANY(0, 77) }),
        'Look up by ANY(media_type_id)';
    is scalar @ats, 3, 'Should have three ATs.';
}

##############################################################################
# Test the list_ids() method.
sub test_list_ids : Test(28) {
    my $self = shift;
    my $class = $self->class;

    # Try ID.
    ok my @at_ids = $class->list_ids({ id => 1 }), 'Look up by ID';
    is scalar @at_ids, 1, 'Should have one AT.';
    ok @at_ids = $class->list_ids({ id => ANY(1, 4) }), 'Look up by ANY(ID)';
    is scalar @at_ids, 2, 'Should have two ATs.';
    like $_, qr/^\d+$/, "Should be an ID" for @at_ids;

    # Try name.
    ok @at_ids = $class->list_ids({ name => 'Move' }), 'Look up by name';
    is scalar @at_ids, 1, 'Should have one AT.';
    ok @at_ids = $class->list_ids({ name => '%' }), 'Look up by name wildcard';
    is scalar @at_ids, 3, 'Should have three ATs.';
    ok @at_ids = $class->list_ids({ name => ANY(qw(Move Email)) }),
        'Look up by ANY(name)';
    is scalar @at_ids, 2, 'Should have two ATs.';

    # Try description.
    ok @at_ids = $class->list_ids({ description => 'Email resources.' }),
        'Look up by description';
    is scalar @at_ids, 1, 'Should have one AT.';
    ok @at_ids = $class->list_ids({ description => '%' }),
        'Look up by description wildcard';
    is scalar @at_ids, 3, 'Should have three ATs.';
    ok @at_ids = $class->list_ids({ description => ANY(qw(email% puts%)) }),
        'Look up by ANY(description)';
    is scalar @at_ids, 2, 'Should have two ATs.';

    # Try media_type.
    ok @at_ids = $class->list_ids({ media_type => 'text/html' }),
        'Look up by media_type';
    is scalar @at_ids, 1, 'Should have one AT.';
    ok @at_ids = $class->list_ids({ media_type => 'text/%' }),
        'Look up by media_type wildcard';
    is scalar @at_ids, 1, 'Should have one AT.';
    ok @at_ids = $class->list_ids({ media_type => ANY(qw(text% none)) }),
        'Look up by ANY(media_type)';
    is scalar @at_ids, 3, 'Should have three ATs.';

    # Try media_type_id.
    ok @at_ids = $class->list_ids({ media_type_id => 0 }),
        'Look up by media_type_id';
    is scalar @at_ids, 2, 'Should have two ATs.';
    ok @at_ids = $class->list_ids({ media_type_id => ANY(0, 77) }),
        'Look up by ANY(media_type_id)';
    is scalar @at_ids, 3, 'Should have three ATs.';
}

1;
__END__

