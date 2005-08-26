package Bric::Util::AlertType::Parts::Rule::DevTest;

use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Util::AlertType;
use Bric::Util::DBI qw(:junction);

sub table { 'alert_type_rule' }

my $et    = Bric::Util::EventType->lookup({ key_name => 'workflow_new'});

my %at_args = (
    event_type_id => $et->get_id,
    owner_id      => __PACKAGE__->user_id,
    name          => 'Testing!',
    subject       => 'Test $name',
    message       => 'Test Message $name'
);

sub alert_type {
    my $self = shift;
    my $at = Bric::Util::AlertType->new({ %at_args, @_ })->save;
    $self->add_del_ids($at->get_id, 'alert_type');
    return $at;
}
my %test_vals = (
    attr      => 'name',
    value    => 'Story',
    operator => 'eq',
);

##############################################################################
# Test construtors.
##############################################################################
# Test lookup().
sub test_lookup : Test(9) {
    my $self = shift;
    ok my $at = $self->alert_type, 'Create new alert type';
    ok my $rule = Bric::Util::AlertType::Parts::Rule->new({
        %test_vals,
        alert_type_id => $at->get_id,
    }), 'Create new rule';
    ok $rule->save, 'Save new rule';
    my $rule_id = $rule->get_id;

    # Look up the new rule.
    ok $rule = Bric::Util::AlertType::Parts::Rule->lookup({ id => $rule_id }),
        'Look up the new rule';

    # Check its attributes.
    is $rule->get_id, $rule_id,                        'Check id';
    is $rule->get_alert_type_id, $at->get_id,          'Check alert_type_id';
    is $rule->get_attr,          $test_vals{attr},     'Check attr';
    is $rule->get_operator,      $test_vals{operator}, 'Check operator';
    is $rule->get_value,         $test_vals{value},    'Check value';
}

##############################################################################
# Test list().
sub test_list : Test(41) {
    my $self = shift;

    ok my $at1 = $self->alert_type,                'Create new alert type';
    ok my $at2 = $self->alert_type(name => 'Foo'), 'Create another alert type';
    my ($atid1, $atid2) = ($at1->get_id, $at2->get_id);
    # Create some test records.
    for my $n (1..5) {
        my %args = %test_vals;
        # Make sure the name is unique.
        $args{value} .= $n;
        if ($n % 2) {
            $args{alert_type_id} = $atid1,
            $args{attr}          = 'description';
            $args{operator}      = 'ne';
        } else {
            $args{alert_type_id} = $atid2,
        }

        ok my $rule = Bric::Util::AlertType::Parts::Rule->new(\%args),
            qq{Create rule with value "$args{value}"};
        ok $rule->save, qq{Save rule with value "$args{value}"};
        # Save the ID for deleting.
        $self->add_del_ids($rule->get_id);
    }

    # Try alert_type_id
    ok my @rules = Bric::Util::AlertType::Parts::Rule->list({
        alert_type_id => $atid1,
    }), 'Search on alert_type_id';
    is scalar @rules, 3, 'Should have three rules';
    ok @rules = Bric::Util::AlertType::Parts::Rule->list({
        alert_type_id => ANY($atid1, $atid2),
    }), 'Search on ANY(alert_type_id)';
    is scalar @rules, 5, 'Should have five rules';
    isa_ok $_, 'Bric::Util::AlertType::Parts::Rule' for @rules;
    my @rule_ids = map { $_->get_id } @rules;

    # Try id
    ok @rules = Bric::Util::AlertType::Parts::Rule->list({
        id => $rule_ids[0],
    }), 'Search on id';
    is scalar @rules, 1, 'Should have one rule';
    ok @rules = Bric::Util::AlertType::Parts::Rule->list({
        id => ANY(@rule_ids),
    }), 'Search on ANY(id)';
    is scalar @rules, 5, 'Should have five rules';

    # Try attr
    ok @rules = Bric::Util::AlertType::Parts::Rule->list({
        attr => 'name',
    }), 'Search on attr';
    is scalar @rules, 2, 'Should have two rules';
    ok @rules = Bric::Util::AlertType::Parts::Rule->list({
        attr => ANY('name', 'description'),
    }), 'Search on ANY(attr)';
    is scalar @rules, 5, 'Should have five rules';
    ok @rules = Bric::Util::AlertType::Parts::Rule->list({
        attr => '%e%',
    }), 'Search on attr with wildcard';
    is scalar @rules, 5, 'Should have five rules';

    # Try operator
    ok @rules = Bric::Util::AlertType::Parts::Rule->list({
        operator => 'eq',
    }), 'Search on operator';
    is scalar @rules, 2, 'Should have two rules';
    ok @rules = Bric::Util::AlertType::Parts::Rule->list({
        operator => ANY('ne', 'eq'),
    }), 'Search on ANY(operator)';
    is scalar @rules, 5, 'Should have five rules';

    # Try value
    ok @rules = Bric::Util::AlertType::Parts::Rule->list({
        value => "$test_vals{value}1",
    }), 'Search on value';
    is scalar @rules, 1, 'Should have one rule';
    ok @rules = Bric::Util::AlertType::Parts::Rule->list({
        value => ANY("$test_vals{value}1", "$test_vals{value}2"),
    }), 'Search on ANY(value)';
    is scalar @rules, 2, 'Should have two rules';
    ok @rules = Bric::Util::AlertType::Parts::Rule->list({
        value => "$test_vals{value}%",
    }), 'Search on value with wildcard';
    is scalar @rules, 5, 'Should have five rules';
}

##############################################################################
# Test href().
sub test_href : Test(46) {
    my $self = shift;

    ok my $at1 = $self->alert_type,                'Create new alert type';
    ok my $at2 = $self->alert_type(name => 'Foo'), 'Create another alert type';
    my ($atid1, $atid2) = ($at1->get_id, $at2->get_id);
    # Create some test records.
    for my $n (1..5) {
        my %args = %test_vals;
        # Make sure the name is unique.
        $args{value} .= $n;
        if ($n % 2) {
            $args{alert_type_id} = $atid1,
            $args{attr}          = 'description';
            $args{operator}      = 'ne';
        } else {
            $args{alert_type_id} = $atid2,
        }

        ok my $rule = Bric::Util::AlertType::Parts::Rule->new(\%args),
            qq{Create rule with value "$args{value}"};
        ok $rule->save, qq{Save rule with value "$args{value}"};
        # Save the ID for deleting.
        $self->add_del_ids($rule->get_id);
    }

    # Try alert_type_id
    ok my $rules = Bric::Util::AlertType::Parts::Rule->href({
        alert_type_id => $atid1,
    }), 'Search on alert_type_id';
    is scalar keys %$rules, 3, 'Should have three rules';
    ok $rules = Bric::Util::AlertType::Parts::Rule->href({
        alert_type_id => ANY($atid1, $atid2),
    }), 'Search on ANY(alert_type_id)';
    is scalar keys %$rules, 5, 'Should have five rules';
    isa_ok $_, 'Bric::Util::AlertType::Parts::Rule' for values %$rules;
    is $_, $rules->{$_}->get_id, "$_ should map to its object"
        for keys %$rules;
    my @rule_ids = map { $_->get_id } values %$rules;

    # Try id
    ok $rules = Bric::Util::AlertType::Parts::Rule->href({
        id => $rule_ids[0],
    }), 'Search on id';
    is scalar keys %$rules, 1, 'Should have one rule';
    ok $rules = Bric::Util::AlertType::Parts::Rule->href({
        id => ANY(@rule_ids),
    }), 'Search on ANY(id)';
    is scalar keys %$rules, 5, 'Should have five rules';

    # Try attr
    ok $rules = Bric::Util::AlertType::Parts::Rule->href({
        attr => 'name',
    }), 'Search on attr';
    is scalar keys %$rules, 2, 'Should have two rules';
    ok $rules = Bric::Util::AlertType::Parts::Rule->href({
        attr => ANY('name', 'description'),
    }), 'Search on ANY(attr)';
    is scalar keys %$rules, 5, 'Should have five rules';
    ok $rules = Bric::Util::AlertType::Parts::Rule->href({
        attr => '%e%',
    }), 'Search on attr with wildcard';
    is scalar keys %$rules, 5, 'Should have five rules';

    # Try operator
    ok $rules = Bric::Util::AlertType::Parts::Rule->href({
        operator => 'eq',
    }), 'Search on operator';
    is scalar keys %$rules, 2, 'Should have two rules';
    ok $rules = Bric::Util::AlertType::Parts::Rule->href({
        operator => ANY('ne', 'eq'),
    }), 'Search on ANY(operator)';
    is scalar keys %$rules, 5, 'Should have five rules';

    # Try value
    ok $rules = Bric::Util::AlertType::Parts::Rule->href({
        value => "$test_vals{value}1",
    }), 'Search on value';
    is scalar keys %$rules, 1, 'Should have one rule';
    ok $rules = Bric::Util::AlertType::Parts::Rule->href({
        value => ANY("$test_vals{value}1", "$test_vals{value}2"),
    }), 'Search on ANY(value)';
    is scalar keys %$rules, 2, 'Should have two rules';
    ok $rules = Bric::Util::AlertType::Parts::Rule->href({
        value => "$test_vals{value}%",
    }), 'Search on value with wildcard';
    is scalar keys %$rules, 5, 'Should have five rules';
}

##############################################################################
# Test class methods.
##############################################################################
# Test list_ids().
sub test_list_ids : Test(41) {
    my $self = shift;

    ok my $at1 = $self->alert_type,                'Create new alert type';
    ok my $at2 = $self->alert_type(name => 'Foo'), 'Create another alert type';
    my ($atid1, $atid2) = ($at1->get_id, $at2->get_id);
    # Create some test records.
    for my $n (1..5) {
        my %args = %test_vals;
        # Make sure the name is unique.
        $args{value} .= $n;
        if ($n % 2) {
            $args{alert_type_id} = $atid1,
            $args{attr}          = 'description';
            $args{operator}      = 'ne';
        } else {
            $args{alert_type_id} = $atid2,
        }

        ok my $rule = Bric::Util::AlertType::Parts::Rule->new(\%args),
            qq{Create rule with value "$args{value}"};
        ok $rule->save, qq{Save rule with value "$args{value}"};
        # Save the ID for deleting.
        $self->add_del_ids($rule->get_id);
    }

    # Try alert_type_id
    ok my @rule_ids = Bric::Util::AlertType::Parts::Rule->list_ids({
        alert_type_id => $atid1,
    }), 'Search on alert_type_id';
    is scalar @rule_ids, 3, 'Should have three rule ids';
    ok @rule_ids = Bric::Util::AlertType::Parts::Rule->list_ids({
        alert_type_id => ANY($atid1, $atid2),
    }), 'Search on ANY(alert_type_id)';
    is scalar @rule_ids, 5, 'Should have five rule ids';
    like $_, qr/^\d+$/, "$_ should be an id" for @rule_ids;
    my @all_ids = @rule_ids;

    # Try id
    ok @rule_ids = Bric::Util::AlertType::Parts::Rule->list_ids({
        id => $all_ids[0],
    }), 'Search on id';
    is scalar @rule_ids, 1, 'Should have one rule id';
    ok @rule_ids = Bric::Util::AlertType::Parts::Rule->list_ids({
        id => ANY(@all_ids),
    }), 'Search on ANY(id)';
    is scalar @rule_ids, 5, 'Should have five rule ids';

    # Try attr
    ok @rule_ids = Bric::Util::AlertType::Parts::Rule->list_ids({
        attr => 'name',
    }), 'Search on attr';
    is scalar @rule_ids, 2, 'Should have two rule ids';
    ok @rule_ids = Bric::Util::AlertType::Parts::Rule->list_ids({
        attr => ANY('name', 'description'),
    }), 'Search on ANY(attr)';
    is scalar @rule_ids, 5, 'Should have five rule ids';
    ok @rule_ids = Bric::Util::AlertType::Parts::Rule->list_ids({
        attr => '%e%',
    }), 'Search on attr with wildcard';
    is scalar @rule_ids, 5, 'Should have five rule ids';

    # Try operator
    ok @rule_ids = Bric::Util::AlertType::Parts::Rule->list_ids({
        operator => 'eq',
    }), 'Search on operator';
    is scalar @rule_ids, 2, 'Should have two rule ids';
    ok @rule_ids = Bric::Util::AlertType::Parts::Rule->list_ids({
        operator => ANY('ne', 'eq'),
    }), 'Search on ANY(operator)';
    is scalar @rule_ids, 5, 'Should have five rule ids';

    # Try value
    ok @rule_ids = Bric::Util::AlertType::Parts::Rule->list_ids({
        value => "$test_vals{value}1",
    }), 'Search on value';
    is scalar @rule_ids, 1, 'Should have one rule id';
    ok @rule_ids = Bric::Util::AlertType::Parts::Rule->list_ids({
        value => ANY("$test_vals{value}1", "$test_vals{value}2"),
    }), 'Search on ANY(value)';
    is scalar @rule_ids, 2, 'Should have two rule ids';
    ok @rule_ids = Bric::Util::AlertType::Parts::Rule->list_ids({
        value => "$test_vals{value}%",
    }), 'Search on value with wildcard';
    is scalar @rule_ids, 5, 'Should have five rule ids';
}

1;
__END__
